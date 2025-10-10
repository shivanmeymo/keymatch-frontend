import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';  // Re-enabled for image picking
import 'package:key_match/widgets/themed_text.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/constants/colors.dart';
import 'package:key_match/main.dart'; // Import MainTabScreen

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String? _imagePath;
  bool _isLoading = false;
  String? _error;
  
  // New fields for gender and birth date
  String _selectedGender = 'M';
  DateTime? _selectedDate;
  final TextEditingController _birthDateController = TextEditingController();
  String _selectedLocationMode = 'local';
  
  // User data fields
  String? _userEmail;
  String? _userName;
  
  // Gender options
  final List<Map<String, String>> _genderOptions = [
    {'value': 'M', 'label': 'Male'},
    {'value': 'F', 'label': 'Female'},
    {'value': 'O', 'label': 'Other'},
  ];

  // Location mode options
  final List<Map<String, String>> _locationModeOptions = [
    {'value': 'local', 'label': 'Local - Find matches near me'},
    {'value': 'global', 'label': 'Global - Find matches worldwide'},
  ];

  @override
  void initState() {
    super.initState();
    _checkProfilePicture();
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _checkProfilePicture() async {
    try {
      print('=== DEBUG: ProfileSetupScreen._checkProfilePicture ===');
      
      // Debug token storage
      await AuthService.debugTokenStorage();
      
      // First check if we have a token
      final token = await AuthService.getToken();
      print('Token available: ${token != null ? 'yes' : 'no'}');
      
      if (token == null) {
        print('No token available, but allowing setup to continue for new users');
        // Don't redirect immediately - allow the setup to continue
        // The user might have just completed email verification
        return;
      }
      
      final user = await AuthService.getCurrentUser();
      print('User data retrieved: ${user != null ? 'yes' : 'no'}');
      
      if (user != null) {
        // Load user data for display
        setState(() {
          _userEmail = user['email'];
          _userName = user['firstName'] != null && user['lastName'] != null 
              ? '${user['firstName']} ${user['lastName']}'
              : user['firstName'] ?? user['lastName'] ?? 'User';
        });
        
        // Check if email is verified
        final isEmailVerified = user['emailVerified'] ?? false;
        print('Email verified: $isEmailVerified');
        
        if (!isEmailVerified) {
          print('Email not verified, redirecting to email verification');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/email-verification');
          }
          return;
        }
        
        // Check if user already has profile picture
        if (user['profile_picture'] != null) {
          print('User already has profile picture, skipping setup');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        print('No user data available, but allowing setup to continue for new users');
        // Don't redirect immediately - allow the setup to continue
        return;
      }
    } catch (error) {
      print('Error checking profile picture: $error');
      // Don't redirect on error - allow the setup to continue
      // Show error message instead
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note: Some profile data may not be loaded yet. You can continue with setup.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
          _error = null;
        });
        print('Selected image from camera: ${image.path}');
      } else {
        print('No image selected from camera');
      }
    } catch (error) {
      print('Error picking image from camera: $error');
      _showErrorDialog('Failed to take photo');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
          _error = null;
        });
        print('Selected image from gallery: ${image.path}');
      } else {
        print('No image selected from gallery');
      }
    } catch (error) {
      print('Error picking image from gallery: $error');
      _showErrorDialog('Failed to pick image from gallery');
    }
  }

  Future<int> _getExistingImagesCount() async {
    try {
      final profile = await ProfileService.getProfile();
      if (profile != null && profile['images'] != null) {
        final images = profile['images'] as List;
        print('User has ${images.length} existing images');
        return images.length;
      }
      return 0;
    } catch (e) {
      print('Error checking existing images: $e');
      return 0;
    }
  }

  Future<void> _handleUploadAndContinue() async {
    // Check how many images user already has
    final existingImagesCount = await _getExistingImagesCount();
    final hasExistingImages = existingImagesCount > 0;
    final hasMaxImages = existingImagesCount >= 6;
    
    print('User has $existingImagesCount existing images');
    
    // Validate form - don't require image if user already has images
    if (!_validateForm(requireImage: !hasExistingImages)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? response;
      
      // Only upload image if user selected one AND doesn't have max images
      if (_imagePath != null && !hasMaxImages) {
        print('Starting upload with image path: $_imagePath');
        response = await ProfileService.uploadProfilePicture(_imagePath!);
        print('Upload response: $response');
      } else if (_imagePath != null && hasMaxImages) {
        print('Skipping image upload - user already has maximum of 6 images');
      } else {
        print('Skipping image upload - no image selected');
      }
      
      print('Updating profile...');
      
      try {
        final user = await AuthService.getCurrentUser();
        final profileData = {
          'bio': user?['bio'] ?? '',
          'birthDate': _selectedDate != null ? _formatDateForAPI(_selectedDate!) : '',
          'gender': _selectedGender,
          'genderPreference': user?['gender_preference'] ?? 'B',
          'relationshipType': user?['relationship_type'] ?? 'C',
          'locationMode': _selectedLocationMode,
        };
          
          print('=== DEBUG: Profile setup - updating profile with data ===');
          print('Bio: ${profileData['bio']}');
          print('Gender: ${profileData['gender']}');
          print('GenderPreference: ${profileData['genderPreference']}');
          print('RelationshipType: ${profileData['relationshipType']}');
          print('LocationMode: ${profileData['locationMode']}');
          
          await ProfileService.updateProfile(
            bio: profileData['bio']!.isEmpty ? null : profileData['bio'],
            birthDate: profileData['birthDate']!.isEmpty ? null : profileData['birthDate'],
            gender: profileData['gender']!,
            genderPreference: profileData['genderPreference']!,
            relationshipType: [profileData['relationshipType']!],
            locationMode: profileData['locationMode']!,
          );
          print('Profile updated successfully');
          
          // Add a small delay to ensure backend has processed the changes
          await Future.delayed(const Duration(milliseconds: 500));
          
        } catch (error) {
          print('Profile update error: $error');
          // Don't throw here, continue to home screen even if profile update fails
        }
        
        print('=== DEBUG: Profile setup complete, navigating to home ===');
        if (mounted) {
          try {
            print('=== DEBUG: Attempting to navigate to /home ===');
            Navigator.pushReplacementNamed(context, '/home');
            print('=== DEBUG: Navigation to /home successful ===');
          } catch (navigationError) {
            print('=== DEBUG: Navigation error: $navigationError ===');
            // Fallback: try to navigate using MaterialPageRoute
            try {
              print('=== DEBUG: Attempting fallback navigation ===');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainTabScreen(),
                ),
              );
              print('=== DEBUG: Fallback navigation successful ===');
            } catch (fallbackError) {
              print('=== DEBUG: Fallback navigation also failed: $fallbackError ===');
              _showErrorDialog('Navigation failed: $fallbackError');
            }
          }
        }
    } catch (error) {
      print('Error in handleUploadAndContinue: $error');
      setState(() {
        _error = error.toString();
      });
      _showErrorDialog(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (error) {
      _showErrorDialog('Failed to sign out');
    }
  }

  Future<void> _handleDeleteAccount() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data including:\n\n'
            '• Your profile and photos\n'
            '• All matches and conversations\n'
            '• Account settings and preferences\n\n'
            'This action is irreversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        final result = await AuthService.deleteAccount();
        
        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Account deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate to login screen
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/signin',
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to delete account'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final DateTime hundredYearsAgo = DateTime(now.year - 100, now.month, now.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? eighteenYearsAgo,
      firstDate: hundredYearsAgo, // 100 years ago
      lastDate: eighteenYearsAgo, // 18 years ago
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  String _formatDateForAPI(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  bool _validateForm({bool requireImage = true}) {
    if (requireImage && _imagePath == null) {
      _showErrorDialog('Please select a profile picture');
      return false;
    }
    if (_selectedDate == null) {
      _showErrorDialog('Please select your birth date');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Profile Setup',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Complete your profile setup',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_userEmail != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_userName != null)
                                Text(
                                  _userName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              Text(
                                _userEmail!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(75),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(73),
                            child: kIsWeb 
                                ? Image.network(
                                    _imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.green,
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.green,
                                      );
                                    },
                                  ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.green,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Profile picture is optional if you already have images',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Gender Selection
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _genderOptions.map((gender) {
                          return Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                gender['label']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              value: gender['value']!,
                              groupValue: _selectedGender,
                              onChanged: _isLoading ? null : (String? value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Birth Date Selection
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Birth Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _isLoading ? null : _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _birthDateController.text.isEmpty
                                      ? 'Select your birth date'
                                      : _birthDateController.text,
                                  style: TextStyle(
                                    color: _birthDateController.text.isEmpty
                                        ? Colors.grey.shade500
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Location Mode Selection
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Preference',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _locationModeOptions.map((mode) {
                          return Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                mode['label']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              value: mode['value']!,
                              groupValue: _selectedLocationMode,
                              onChanged: _isLoading ? null : (String? value) {
                                setState(() {
                                  _selectedLocationMode = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUploadAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3, 
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSignOut,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleDeleteAccount,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 