import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';  // Re-enabled for image picking
import 'package:key_match/widgets/themed_text.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/constants/colors.dart';

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
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        // Check if email is verified
        final isEmailVerified = user['emailVerified'] ?? false;
        
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
      }
    } catch (error) {
      print('Error checking profile picture: $error');
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

  Future<void> _handleUploadAndContinue() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting upload with image path: $_imagePath');
      final response = await ProfileService.uploadProfilePicture(_imagePath!);
      print('Upload response: $response');
      
      if (response['images'] != null && response['images'].isNotEmpty) {
        print('Upload successful, updating profile...');
        
        // Update the user's stored data with the new profile picture
        final imageUrl = response['images'][0]['imageUrl'];
        await AuthService.updateUserProfilePicture(imageUrl);
        
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
          await ProfileService.updateProfile(
            bio: profileData['bio']!,
            birthDate: profileData['birthDate']!,
            gender: profileData['gender']!,
            genderPreference: profileData['genderPreference']!,
            relationshipType: [profileData['relationshipType']!],
            locationMode: profileData['locationMode']!,
          );
          print('Profile updated successfully');
        } catch (error) {
          print('Profile update error: $error');
        }
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception('Failed to upload profile picture - no image URL received');
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
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

  bool _validateForm() {
    if (_imagePath == null) {
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
                        color: Colors.blue,
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
                                        color: Colors.blue,
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
                                        color: Colors.blue,
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
                                color: Colors.blue,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
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
                                style: const TextStyle(fontSize: 14),
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
                              const Icon(Icons.calendar_today, color: Colors.blue),
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
                                style: const TextStyle(fontSize: 14),
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
                      backgroundColor: Colors.blue,
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
                TextButton(
                  onPressed: _isLoading ? null : _handleSignOut,
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.blue),
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