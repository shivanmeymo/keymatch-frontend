import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  // Re-enabled for profile picture selection
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/services/keyword_service.dart';
import 'package:key_match/screens/premium_subscription_screen.dart';
import 'package:key_match/constants/colors.dart';
import 'package:key_match/widgets/enhanced_keyword_input.dart';
import 'package:key_match/widgets/enhanced_keyword_display.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class ProfileTab extends StatefulWidget {
  final Function(int) navigateToTab;

  const ProfileTab({Key? key, required this.navigateToTab}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploading = false;
  String? _error;
  bool _isProfileComplete = false;
  bool _isAccountHidden = false;
  bool _isLoadingVisibility = false;
  
  // Form controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _keyWordsController = TextEditingController();
  String _selectedGender = 'M';
  String _selectedGenderPreference = 'B';
  Set<String> _selectedRelationshipTypes = {'C'}; // Changed to Set for multiple selection
  List<String> _keyWords = [];

  // Options for Relationship Types
  final Map<String, String> _relationshipTypeOptions = {
    'C': 'Casual',
    'S': 'Serious',
    'F': 'Friendship',
    'B': 'Business',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAccountVisibility();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _keyWordsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await ProfileService.getProfile();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });

        // Check if profile is complete (user has finished initial setup)
        _isProfileComplete = ProfileService.isProfileComplete(profile);

        // Initialize form controllers with current values
        _bioController.text = profile['bio'] ?? '';
        
        // Set gender with validation
        final genderValue = profile['gender'];
        _selectedGender = (genderValue == 'M' || genderValue == 'F' || genderValue == 'O') ? genderValue : 'M';
        
        // Set gender preference with validation
        final genderPrefValue = profile['genderPreference'];
        _selectedGenderPreference = (genderPrefValue == 'M' || genderPrefValue == 'W' || genderPrefValue == 'B') ? genderPrefValue : 'B';
        
        // Set relationship type with validation
        final relationshipValue = profile['relationshipType'];
        if (relationshipValue is List) {
          _selectedRelationshipTypes = Set<String>.from(
            relationshipValue.map((item) => item.toString()).where((item) => _relationshipTypeOptions.containsKey(item))
          );
        } else if (relationshipValue is String) {
          // If it's a string, it might be comma-separated (from old data) or single.
          // The backend model's getter should return a List, so this is defensive.
          _selectedRelationshipTypes = Set<String>.from(
            relationshipValue.split(',').map((s) => s.trim()).where((item) => _relationshipTypeOptions.containsKey(item))
          );
        } else {
          // Default if null or unexpected type
          _selectedRelationshipTypes = {}; // Start with empty, then add default if needed
        }
        // Ensure 'C' is added if the set is empty after processing (no valid types found or value was null)
        if (_selectedRelationshipTypes.isEmpty) {
          _selectedRelationshipTypes.add('C');
        }
        
        // Initialize key words
        if (profile['keyWords'] != null && profile['keyWords'] is List) {
          _keyWords = List<String>.from(profile['keyWords']);
        } else {
          _keyWords = [];
        }
        _keyWordsController.text = _keyWords.join(', ');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAccountVisibility() async {
    try {
      setState(() {
        _isLoadingVisibility = true;
      });

      final isHidden = await ProfileService.getAccountVisibility();
      
      if (mounted) {
        setState(() {
          _isAccountHidden = isHidden;
          _isLoadingVisibility = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingVisibility = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load account visibility: $error')),
        );
      }
    }
  }

  Future<void> _toggleAccountVisibility() async {
    try {
      setState(() {
        _isLoadingVisibility = true;
      });

      if (_isAccountHidden) {
        // Unhide account
        await ProfileService.unhideAccount();
        if (mounted) {
          setState(() {
            _isAccountHidden = false;
            _isLoadingVisibility = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account is now visible to others')),
          );
        }
      } else {
        // Hide account
        await ProfileService.hideAccount();
        if (mounted) {
          setState(() {
            _isAccountHidden = true;
            _isLoadingVisibility = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account is now hidden from others')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingVisibility = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update account visibility: $error')),
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $error')),
        );
      }
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

  Future<void> _pickImage() async {
    try {
      // Check if user already has 6 images
      final imageCount = _userProfile?['images']?.length ?? 0;
      if (imageCount >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum of 6 images allowed. Please delete an image first.')),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(image.path);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $error')),
      );
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    try {
      setState(() {
        _isUploading = true;
      });

      await ProfileService.uploadProfilePicture(imagePath);
      
      // Reload profile to get updated images
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use current keywords from the enhanced input
      List<String> keyWords = List<String>.from(_keyWords);

      // Track keyword usage for analytics
      if (keyWords.isNotEmpty) {
        try {
          await KeywordService.trackKeywordUsage(keyWords);
        } catch (e) {
          // Silent fail for analytics
          print('Warning: Failed to track keyword usage: $e');
        }
      }

      // Update image order if necessary
      if (_userProfile?['images'] != null) {
        List<Map<String, dynamic>> images = List<Map<String, dynamic>>.from(_userProfile!['images']);
        if (images.isNotEmpty) {
          for (int i = 0; i < images.length; i++) {
            images[i]['isPrimary'] = (i == 0);
          }
          _userProfile!['images'] = images; // Update the local state as well for UI consistency
          
          // Transform images to the format backend expects: { imageId, order }
          final imageOrders = images.asMap().entries.map((entry) {
            return {
              'imageId': entry.value['id'],
              'order': entry.key,
            };
          }).toList();
          
          await ProfileService.updateImageOrder(imageOrders);
        }
      }

      await ProfileService.updateProfile(
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        birthDate: _userProfile?['birthDate'],
        gender: _selectedGender, // Allow gender updates regardless of profile completion
        genderPreference: _selectedGenderPreference,
        relationshipType: _selectedRelationshipTypes.toList(), // Pass the list of relationship types
        keyWords: _keyWords.isNotEmpty ? _keyWords : null,
      );

      // Reload profile to get updated data
      await _loadProfile();

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      print('Profile save error: $error');
      
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
        
        // Show more specific error message
        String errorMessage = 'Failed to update profile';
        if (error.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please check your connection and try again.';
        } else if (error.toString().contains('Network connection failed')) {
          errorMessage = 'Network connection failed. Please check your internet connection.';
        } else if (error.toString().contains('Validation error')) {
          errorMessage = 'Invalid profile data. Please check your input and try again.';
        } else if (error.toString().contains('Server error')) {
          errorMessage = 'Server error. Please try again later.';
        } else if (error.toString().contains('Key words must be an array')) {
          errorMessage = 'Invalid keyword format. Please try again.';
        } else {
          errorMessage = error.toString().replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getUserName() {
    if (_userProfile?['user'] != null) {
      final user = _userProfile!['user'];
      final firstName = user['firstName'] ?? '';
      final lastName = user['lastName'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return '';
  }

  String _getUserEmail() {
    if (_userProfile?['user'] != null) {
      return _userProfile!['user']['email'] ?? '';
    }
    return '';
  }

  String _getProfileImageUrl() {
    if (_userProfile?['images'] != null && _userProfile!['images'].isNotEmpty) {
      // Find the primary image first
      final primaryImage = _userProfile!['images'].firstWhere(
        (image) => image['isPrimary'] == true,
        orElse: () => _userProfile!['images'][0], // Fallback to first image
      );
      
      String? imageUrl = primaryImage['imageUrl'];
      
      // Use the centralized method from ProfileService
      final fullUrl = ProfileService.getFullImageUrl(imageUrl);
      return fullUrl;
    }
    
    // Fallback to profilePicture
    if (_userProfile?['profilePicture'] != null) {
      final imageUrl = _userProfile!['profilePicture'];
      return ProfileService.getFullImageUrl(imageUrl);
    }
    
    return '';
  }

  bool _isValidProfileImageUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Hero Section with Profile Picture and Basic Info
                        if (!_isEditing)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primaryGreen,
                                  AppColors.primaryGreenLight,
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    // Profile Picture
                                    GestureDetector(
                                      onTap: _isEditing && !_isUploading ? _pickImage : null,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 4,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 56,
                                              backgroundImage: _isValidProfileImageUrl(_getProfileImageUrl())
                                                  ? NetworkImage(_getProfileImageUrl())
                                                  : null,
                                              child: !_isValidProfileImageUrl(_getProfileImageUrl())
                                                  ? const Icon(Icons.person, size: 60, color: Colors.white70)
                                                  : null,
                                                            onBackgroundImageError: _isValidProfileImageUrl(_getProfileImageUrl())
                  ? (exception, stackTrace) {
                      // The error will be handled by the child fallback
                    }
                  : null,
                                            ),
                                          ),
                                          if (_isUploading)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(60),
                                                ),
                                                child: const Center(
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (_isEditing && !_isUploading)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accentGreen,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Name
                                    Text(
                                      _getUserName(),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Email
                                    Text(
                                      _getUserEmail(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    
                                    // Premium Status Text
                                    FutureBuilder<bool>(
                                      future: PremiumService.isPremium(),
                                      builder: (context, snapshot) {
                                        final isPremium = snapshot.data ?? false;
                                        
                                        if (isPremium) {
                                          return FutureBuilder<DateTime?>(
                                            future: PremiumService.getPremiumExpiry(),
                                            builder: (context, expirySnapshot) {
                                              final expiry = expirySnapshot.data;
                                              String statusText = 'Premium Member';
                                              
                                              if (expiry != null) {
                                                final now = DateTime.now();
                                                final daysUntilExpiry = expiry.difference(now).inDays;
                                                
                                                if (daysUntilExpiry > 0) {
                                                  statusText = 'Premium Member • Expires in $daysUntilExpiry days';
                                                } else if (daysUntilExpiry == 0) {
                                                  statusText = 'Premium Member • Expires today';
                                                } else {
                                                  statusText = 'Premium Member • Expired';
                                                }
                                              }
                                              
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      statusText,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.amber,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Action Buttons Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Edit Profile Button
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _isEditing = true;
                                                });
                                              },
                                              icon: const Icon(Icons.edit, size: 18),
                                              label: const Text('Edit'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: AppColors.primaryGreen,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        // Premium Status/Button
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            child: FutureBuilder<bool>(
                                              future: PremiumService.isPremium(),
                                              builder: (context, snapshot) {
                                                final isPremium = snapshot.data ?? false;
                                                
                                                if (isPremium) {
                                                  return FutureBuilder<DateTime?>(
                                                    future: PremiumService.getPremiumExpiry(),
                                                    builder: (context, expirySnapshot) {
                                                      final expiry = expirySnapshot.data;
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(25),
                                                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color: Colors.white,
                                                              size: 18,
                                                            ),
                                                            const SizedBox(width: 6),
                                                            const Text(
                                                              'Premium',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  return ElevatedButton.icon(
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => const PremiumSubscriptionScreen(),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(Icons.star, size: 18),
                                                    label: const Text('Premium'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.accentGreen,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(25),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        // Content Sections
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Photos Section
                              _buildPhotosSection(),
                              
                              const SizedBox(height: 24),
                              
                              // Profile Details Section
                              _buildProfileDetailsSection(),
                              
                              const SizedBox(height: 24),
                              
                              // Account Section
                              _buildAccountSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _getGenderText(String? gender) {
    switch (gender) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return 'Not specified';
    }
  }

  String _getGenderPreferenceText(String? preference) {
    switch (preference) {
      case 'M':
        return 'Men';
      case 'W':
        return 'Women';
      case 'B':
        return 'Both';
      default:
        return 'Not specified';
    }
  }

  String _getRelationshipTypeText(String type) {
    switch (type) {
      case 'C':
        return 'Casual';
      case 'S':
        return 'Serious';
      case 'F':
        return 'Friendship';
      case 'B':
        return 'Business';
      default:
        return 'Not specified';
    }
  }

  String _getRelationshipTypesText(dynamic types) {
    if (types == null) return 'Not specified';
    
    List<String> typeList;
    if (types is List) {
      typeList = types.cast<String>();
    } else if (types is String) {
      // Handle legacy single value format
      typeList = [types];
    } else {
      return 'Not specified';
    }
    
    if (typeList.isEmpty) return 'Not specified';
    
    return typeList.map((type) => _getRelationshipTypeText(type)).join(', ');
  }

  String _getLocationModeText(String? mode) {
    switch (mode) {
      case 'local':
        return 'Local - Find matches near me';
      case 'global':
        return 'Global - Find matches worldwide';
      default:
        return 'Not specified';
    }
  }

  Future<void> _deleteImage(String imageId) async {
    try {
      await ProfileService.deleteImage(imageId);
      
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete image: $error')),
        );
      }
    }
  }

  Widget _buildRelationshipTypeChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _relationshipTypeOptions.entries.map((entry) {
        final value = entry.key;
        final label = entry.value;
        final isSelected = _selectedRelationshipTypes.contains(value);
        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected 
                ? Colors.white
                : Colors.black87,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedRelationshipTypes.add(value);
              } else {
                // Prevent removing the last item if it's the only one selected
                if (_selectedRelationshipTypes.length > 1) {
                  _selectedRelationshipTypes.remove(value);
                } else {
                  // Optionally, show a message or handle as per UX requirements
                  // For now, just prevent deselection of the last item
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('At least one relationship type must be selected.')),
                  );
                }
              }
            });
          },
          selectedColor: AppColors.primaryGreen,
          backgroundColor: Colors.grey.shade100,
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected ? AppColors.primaryGreen : Colors.grey.shade400,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageGrid() {
    final images = _userProfile?['images'] as List? ?? [];
    final bool canAddMoreImages = images.length < 6;

    if (_isEditing) {
      // Make a mutable copy for reordering
      List reorderableImages = List.from(images);

      return ReorderableGridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: reorderableImages.length + (canAddMoreImages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == reorderableImages.length && canAddMoreImages) {
            // Add photo button - only show in edit mode
            return buildAddImageButton(key: const ValueKey('add_button'));
          }

          final image = reorderableImages[index];
          // Ensure image and image['id'] are not null before creating ValueKey
          final imageId = image['id']?.toString() ?? 'image_$index';
          return buildImageItem(image, key: ValueKey(imageId));
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            // Adjust newIndex if dragging before the add button (if visible)
            // This logic assumes add button is always at the end of reorderable items
            if (canAddMoreImages && newIndex >= reorderableImages.length) {
              newIndex = reorderableImages.length -1; // Place before add button effectively
            }

            final item = reorderableImages.removeAt(oldIndex);
            reorderableImages.insert(newIndex, item);
            
            // Update primary image status - first image (index 0) becomes primary
            for (int i = 0; i < reorderableImages.length; i++) {
              reorderableImages[i]['isPrimary'] = (i == 0);
            }
            
            _userProfile!['images'] = List<Map<String, dynamic>>.from(reorderableImages.cast<Map<String, dynamic>>());
            
            // Update the image order on the backend
            _updateImageOrder(reorderableImages);
          });
        },
        // Optional: Add a footer for the add button if it simplifies logic,
        // but ReorderableGridView.builder doesn't directly support a footer like .count does.
        // So, handling it as a regular item (conditionally) is more straightforward here.
      );
    } else {
      // Original GridView for non-editing mode - NO ADD BUTTON
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: images.length, // Only show existing images, no add button
        itemBuilder: (context, index) {
          if (index < images.length) {
            final image = images[index];
            return buildImageItem(image);
          }
          return const SizedBox.shrink();
        },
      );
    }
  }

  Widget buildAddImageButton({Key? key}) {
    return GestureDetector(
      key: key,
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        child: Icon(
          Icons.add_photo_alternate,
          size: 40,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget buildImageItem(Map<String, dynamic> image, {Key? key}) {
    String? imageUrl = image['imageUrl'];
    final fullUrl = ProfileService.getFullImageUrl(imageUrl);

    return Stack(
      key: key,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: fullUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(fullUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            color: fullUrl.isEmpty ? Theme.of(context).colorScheme.surface : null,
          ),
          child: fullUrl.isEmpty
              ? Icon(Icons.image, size: 40, color: Theme.of(context).colorScheme.onSurface)
              : null,
        ),
        if (_isEditing)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                _deleteImage(image['id'].toString());
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // Show image number instead of "Primary"
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_getImageNumber(image)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get image number based on position
  int _getImageNumber(Map<String, dynamic> image) {
    final images = _userProfile?['images'] as List? ?? [];
    for (int i = 0; i < images.length; i++) {
      if (images[i]['id'] == image['id']) {
        return i + 1; // Return 1-based index
      }
    }
    return 1; // Fallback
  }

  // Update image order on the backend
  Future<void> _updateImageOrder(List reorderableImages) async {
    try {
      // Transform images to the format backend expects: { imageId, order }
      final imageOrders = reorderableImages.asMap().entries.map((entry) {
        return {
          'imageId': entry.value['id'],
          'order': entry.key,
        };
      }).toList();
      
      await ProfileService.updateImageOrder(imageOrders);
    } catch (error) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update image order: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPhotosSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Photos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                if (_userProfile?['images'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_userProfile!['images'].length}/6',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildImageGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                if (_isEditing)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            // Reset form values
                            _bioController.text = _userProfile?['bio'] ?? '';
                            
                            // Reset gender with validation
                            final genderValue = _userProfile?['gender'];
                            _selectedGender = (genderValue == 'M' || genderValue == 'F' || genderValue == 'O') ? genderValue : 'M';
                            
                            // Reset gender preference with validation
                            final genderPrefValue = _userProfile?['genderPreference'];
                            _selectedGenderPreference = (genderPrefValue == 'M' || genderPrefValue == 'W' || genderPrefValue == 'B') ? genderPrefValue : 'B';
                            
                            // Reset relationship type with validation
                            final relationshipValue = _userProfile?['relationshipType'];
                            if (relationshipValue is List) {
                              _selectedRelationshipTypes = Set<String>.from(
                                relationshipValue.map((item) => item.toString()).where((item) => _relationshipTypeOptions.containsKey(item))
                              );
                            } else if (relationshipValue is String) {
                              _selectedRelationshipTypes = Set<String>.from(
                                relationshipValue.split(',').map((s) => s.trim()).where((item) => _relationshipTypeOptions.containsKey(item))
                              );
                            } else {
                              _selectedRelationshipTypes = {};
                            }
                            if (_selectedRelationshipTypes.isEmpty) {
                              _selectedRelationshipTypes.add('C');
                            }
                            
                            // Reset key words
                            if (_userProfile?['keyWords'] != null && _userProfile!['keyWords'] is List) {
                              _keyWords = List<String>.from(_userProfile!['keyWords']);
                            } else {
                              _keyWords = [];
                            }
                            _keyWordsController.text = _keyWords.join(', ');
                          });
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Bio
            _buildDetailItem(
              'Bio',
              _isEditing
                  ? TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Tell us about yourself...',
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final bio = _userProfile?['bio'];
                        return Text(
                          bio?.toString().isNotEmpty == true ? bio.toString() : 'No bio yet',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimaryLight,
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Age
            _buildDetailItem(
              'Age',
              _isEditing
                  ? _buildBirthDatePicker()
                  : Builder(
                      builder: (context) {
                        final age = _userProfile?['age'];
                        final birthDate = _userProfile?['birthDate'];
                        if (age != null) {
                          return Text(
                            '$age years old',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimaryLight,
                            ),
                          );
                        } else if (birthDate != null) {
                          // Calculate age from birth date if age is not provided
                          try {
                            final birthDateTime = DateTime.parse(birthDate);
                            final now = DateTime.now();
                            int calculatedAge = now.year - birthDateTime.year;
                            if (now.month < birthDateTime.month || 
                                (now.month == birthDateTime.month && now.day < birthDateTime.day)) {
                              calculatedAge--;
                            }
                            return Text(
                              '$calculatedAge years old',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimaryLight,
                              ),
                            );
                          } catch (e) {
                            return Text(
                              'Age not available',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondaryLight,
                              ),
                            );
                          }
                        } else {
                          return Text(
                            'Age not set',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondaryLight,
                            ),
                          );
                        }
                      },
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Key Words
            _buildDetailItem(
              'Key Words',
              _isEditing
                  ? EnhancedKeywordInput(
                      currentKeywords: _keyWords,
                      onKeywordsChanged: (newKeywords) {
                        setState(() {
                          _keyWords = newKeywords;
                        });
                      },
                      hintText: 'Enter key words separated by commas...',
                      helperText: 'e.g., adventurous, creative, music lover, coffee addict',
                    )
                  : EnhancedKeywordDisplay(
                      keywords: _userProfile?['keyWords'] != null && 
                               _userProfile!['keyWords'] is List
                          ? List<String>.from(_userProfile!['keyWords'].map((word) => word.toString()))
                          : [],
                      isEditing: false,
                      initialDisplayCount: 15,
                      maxHeight: 180,
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Gender
            _buildDetailItem(
              'Gender',
              _isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: 'Select gender',
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Male')),
                            DropdownMenuItem(value: 'F', child: Text('Female')),
                            DropdownMenuItem(value: 'O', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value ?? 'M';
                            });
                          },
                        ),

                      ],
                    )
                  : Builder(
                      builder: (context) {
                        final gender = _userProfile?['gender'];
                        final genderText = _getGenderText(gender);
                        return Text(
                          genderText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimaryLight,
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Gender Preference
            _buildDetailItem(
              'Interested in',
              _isEditing
                  ? DropdownButtonFormField<String>(
                      value: _selectedGenderPreference,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select preference',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Men')),
                        DropdownMenuItem(value: 'W', child: Text('Women')),
                        DropdownMenuItem(value: 'B', child: Text('Both')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGenderPreference = value ?? 'B';
                        });
                      },
                    )
                  : Text(
                      _getGenderPreferenceText(_userProfile?['genderPreference']),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Relationship Type
            _buildDetailItem(
              'Looking for',
              _isEditing
                  ? _buildRelationshipTypeChips()
                  : Text(
                      _getRelationshipTypesText(_userProfile?['relationshipType']),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Location Mode
            _buildDetailItem(
              'Location Preference',
              _isEditing
                  ? DropdownButtonFormField<String>(
                      value: _userProfile?['locationMode'] ?? 'local',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select location preference',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'local', child: Text('Local - Find matches near me')),
                        DropdownMenuItem(value: 'global', child: Text('Global - Find matches worldwide')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (_userProfile != null) {
                            _userProfile!['locationMode'] = value ?? 'local';
                          }
                        });
                      },
                    )
                  : Text(
                      _getLocationModeText(_userProfile?['locationMode']),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            
            // Account Visibility Toggle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingVisibility ? null : _toggleAccountVisibility,
                    icon: _isLoadingVisibility 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isAccountHidden ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                        ),
                    label: Text(
                      _isLoadingVisibility 
                        ? 'Updating...'
                        : _isAccountHidden ? 'Make Visible' : 'Hide Account',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAccountHidden ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Delete Account Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleDeleteAccount,
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildBirthDatePicker() {
    DateTime? selectedDate;
    String displayText = 'Select birth date';
    
    // Parse current birth date if available
    if (_userProfile?['birthDate'] != null) {
      try {
        selectedDate = DateTime.parse(_userProfile!['birthDate']);
        displayText = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
      } catch (e) {
        // If parsing fails, keep default text
      }
    }
    
    return InkWell(
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
        final DateTime hundredYearsAgo = DateTime(now.year - 100, now.month, now.day);
        
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? eighteenYearsAgo,
          firstDate: hundredYearsAgo,
          lastDate: eighteenYearsAgo,
        );
        
        if (picked != null) {
          setState(() {
            if (_userProfile != null) {
              _userProfile!['birthDate'] = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayText,
              style: TextStyle(
                color: selectedDate != null ? AppColors.textPrimaryLight : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}