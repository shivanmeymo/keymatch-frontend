import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';  // Re-enabled for profile picture selection
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/screens/premium_features_screen.dart';
import 'package:key_match/screens/premium_subscription_screen.dart';
import 'package:key_match/widgets/themed_text.dart';
import 'package:key_match/widgets/themed_view.dart';
import 'package:key_match/widgets/premium_upgrade_widget.dart';
import 'dart:io';
import 'package:key_match/constants/colors.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploading = false;
  String? _error;
  
  // Form controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _keyWordsController = TextEditingController();
  String _selectedGender = 'M';
  String _selectedGenderPreference = 'B';
  Set<String> _selectedRelationshipTypes = {'C'}; // Changed to Set for multiple selection
  List<String> _keyWords = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

        // Debug logging
        print('=== DEBUG: Profile loading ===');
        print('Profile gender: ${profile['gender']}');
        print('Profile genderPreference: ${profile['genderPreference']}');
        print('Profile relationshipType: ${profile['relationshipType']}');

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
          _selectedRelationshipTypes = Set<String>.from(relationshipValue);
        } else if (relationshipValue is String) {
          // Handle legacy single value format
          _selectedRelationshipTypes = {relationshipValue};
        } else {
          _selectedRelationshipTypes = {'C'};
        }
        
        // Debug logging after validation
        print('=== DEBUG: After validation ===');
        print('Selected gender: $_selectedGender');
        print('Selected genderPreference: $_selectedGenderPreference');
        print('Selected relationshipTypes: $_selectedRelationshipTypes');
        
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

      // Debug logging before save
      print('=== DEBUG: Saving profile ===');
      print('Selected gender: $_selectedGender');
      print('Selected genderPreference: $_selectedGenderPreference');
      print('Selected relationshipTypes: $_selectedRelationshipTypes');
      print('Bio: ${_bioController.text}');

      // Parse key words from text input
      List<String> keyWords = [];
      if (_keyWordsController.text.trim().isNotEmpty) {
        keyWords = _keyWordsController.text
            .split(',')
            .map((word) => word.trim())
            .where((word) => word.isNotEmpty)
            .toList();
      }

      await ProfileService.updateProfile(
        bio: _bioController.text,
        gender: _selectedGender,
        genderPreference: _selectedGenderPreference,
        relationshipType: _selectedRelationshipTypes.toList(),
        keyWords: keyWords,
        locationMode: _userProfile?['locationMode'] ?? 'local',
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
        } else {
          errorMessage = error.toString().replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
    print('=== DEBUG: Getting profile image URL ===');
    print('User profile keys: ${_userProfile?.keys.toList()}');
    
    if (_userProfile?['images'] != null && _userProfile!['images'].isNotEmpty) {
      print('Images array found with ${_userProfile!['images'].length} images');
      
      // Find the primary image first
      final primaryImage = _userProfile!['images'].firstWhere(
        (image) => image['isPrimary'] == true,
        orElse: () => _userProfile!['images'][0], // Fallback to first image
      );
      
      print('Selected image: $primaryImage');
      String? imageUrl = primaryImage['imageUrl'];
      print('Extracted imageUrl: $imageUrl');
      
      // Use the centralized method from ProfileService
      final fullUrl = ProfileService.getFullImageUrl(imageUrl);
      print('Full URL from ProfileService: $fullUrl');
      return fullUrl;
    } else {
      print('No images found in profile');
    }
    
    // Fallback to profilePicture
    if (_userProfile?['profilePicture'] != null) {
      final imageUrl = _userProfile!['profilePicture'];
      print('Using profilePicture fallback: $imageUrl');
      return ProfileService.getFullImageUrl(imageUrl);
    }
    
    print('No image URL found, returning empty string');
    return '';
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
                          fontSize: 18,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Profile Header and Details (moved to top)
                        if (!_isEditing) // Only show profile header when not editing
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Profile Picture
                                  GestureDetector(
                                    onTap: _isUploading ? null : _pickImage,
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 60,
                                          backgroundImage: _getProfileImageUrl().isNotEmpty
                                              ? NetworkImage(_getProfileImageUrl())
                                              : null,
                                          child: _getProfileImageUrl().isEmpty
                                              ? const Icon(Icons.person, size: 60)
                                              : null,
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Name
                                  Text(
                                    _getUserName(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                                  // Email
                                  Text(
                                    _getUserEmail(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Edit Profile Button
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Edit Profile'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.tintColorLight,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                  
                                  // Go Premium Button
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const PremiumFeaturesScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.star, color: Colors.white),
                                    label: const Text('Go Premium'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.greenAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Photos Section (moved below profile header)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'My Photos',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_userProfile?['images'] != null)
                                      Text(
                                        '${_userProfile!['images'].length}/6',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: (_userProfile?['images']?.length ?? 0) + 
                                            ((_userProfile?['images']?.length ?? 0) < 6 ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    final images = _userProfile?['images'] as List? ?? [];
                                    
                                    if (index == images.length && images.length < 6) {
                                      // Add photo button
                                      return GestureDetector(
                                        onTap: _isUploading ? null : _pickImage,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!, width: 1),
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    }
                                    
                                    if (index < images.length) {
                                      final image = images[index];
                                      String? imageUrl = image['imageUrl'];
                                      
                                      // Use the centralized method from ProfileService
                                      final fullUrl = ProfileService.getFullImageUrl(imageUrl);
                                      
                                      return Stack(
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
                                              color: fullUrl.isEmpty ? Colors.grey[200] : null,
                                            ),
                                            child: fullUrl.isEmpty
                                                ? const Icon(Icons.image, size: 40, color: Colors.grey)
                                                : null,
                                          ),
                                          if (_isEditing)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () {
                                                  print('🔍 Delete button tapped for image: $image');
                                                  print('🔍 Image ID: ${image['id']}');
                                                  print('🔍 Image ID type: ${image['id'].runtimeType}');
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
                                          if (image['isPrimary'] == true)
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Primary',
                                                  style: TextStyle(
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
                                    
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Profile Details
                        Card(
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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
                                                  _selectedRelationshipTypes = Set<String>.from(relationshipValue);
                                                } else if (relationshipValue is String) {
                                                  // Handle legacy single value format
                                                  _selectedRelationshipTypes = {relationshipValue};
                                                } else {
                                                  _selectedRelationshipTypes = {'C'};
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
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: _saveProfile,
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Bio
                                const Text(
                                  'Bio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  TextField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Tell us about yourself...',
                                    ),
                                  )
                                else
                                  Text(
                                    _userProfile?['bio'] ?? 'No bio yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _userProfile?['bio'] != null ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                
                                const SizedBox(height: 16),
                                
                                // Key Words
                                const Text(
                                  'Key Words',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _keyWordsController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Enter key words separated by commas...',
                                          helperText: 'e.g., adventurous, creative, music lover, coffee addict',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (_keyWords.isNotEmpty)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: _keyWords.map((word) => Chip(
                                            label: Text(word),
                                            deleteIcon: const Icon(Icons.close, size: 16),
                                            onDeleted: () {
                                              setState(() {
                                                _keyWords.remove(word);
                                                _keyWordsController.text = _keyWords.join(', ');
                                              });
                                            },
                                          )).toList(),
                                        ),
                                    ],
                                  )
                                else
                                  _userProfile?['keyWords'] != null && 
                                  _userProfile!['keyWords'] is List && 
                                  (_userProfile!['keyWords'] as List).isNotEmpty
                                      ? Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: (_userProfile!['keyWords'] as List)
                                              .map((word) => Chip(
                                                    label: Text(word.toString()),
                                                    backgroundColor: Colors.blue[100],
                                                    labelStyle: TextStyle(
                                                      color: Colors.blue[800],
                                                      fontSize: 14,
                                                    ),
                                                  ))
                                              .toList(),
                                        )
                                      : Text(
                                          'No key words yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                
                                const SizedBox(height: 16),
                                
                                // Gender
                                const Text(
                                  'Gender',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Select gender',
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
                                  )
                                else
                                  Text(
                                    _getGenderText(_userProfile?['gender']),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                
                                const SizedBox(height: 16),
                                
                                // Gender Preference
                                const Text(
                                  'Interested in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  DropdownButtonFormField<String>(
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
                                else
                                  Text(
                                    _getGenderPreferenceText(_userProfile?['genderPreference']),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                
                                const SizedBox(height: 16),
                                
                                // Relationship Type
                                const Text(
                                  'Looking for',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CheckboxListTile(
                                        title: const Text('Casual'),
                                        value: _selectedRelationshipTypes.contains('C'),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedRelationshipTypes.add('C');
                                            } else {
                                              _selectedRelationshipTypes.remove('C');
                                            }
                                          });
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      CheckboxListTile(
                                        title: const Text('Serious'),
                                        value: _selectedRelationshipTypes.contains('S'),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedRelationshipTypes.add('S');
                                            } else {
                                              _selectedRelationshipTypes.remove('S');
                                            }
                                          });
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      CheckboxListTile(
                                        title: const Text('Friendship'),
                                        value: _selectedRelationshipTypes.contains('F'),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedRelationshipTypes.add('F');
                                            } else {
                                              _selectedRelationshipTypes.remove('F');
                                            }
                                          });
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      CheckboxListTile(
                                        title: const Text('Business'),
                                        value: _selectedRelationshipTypes.contains('B'),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedRelationshipTypes.add('B');
                                            } else {
                                              _selectedRelationshipTypes.remove('B');
                                            }
                                          });
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    _getRelationshipTypesText(_userProfile?['relationshipType']),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                
                                const SizedBox(height: 16),
                                
                                // Location Mode (Local/Global)
                                const Text(
                                  'Location Preference',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isEditing)
                                  DropdownButtonFormField<String>(
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
                                        // Update the profile data directly
                                        if (_userProfile != null) {
                                          _userProfile!['locationMode'] = value ?? 'local';
                                        }
                                      });
                                    },
                                  )
                                else
                                  Text(
                                    _getLocationModeText(_userProfile?['locationMode']),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Premium Section
                        FutureBuilder<bool>(
                          future: PremiumService.isPremium(),
                          builder: (context, snapshot) {
                            final isPremium = snapshot.data ?? false;
                            
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isPremium ? Icons.star : Icons.star_border,
                                          color: isPremium ? AppColors.activeTabYellow : Colors.grey,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Premium Status',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    if (isPremium) ...[
                                      FutureBuilder<DateTime?>(
                                        future: PremiumService.getPremiumExpiry(),
                                        builder: (context, expirySnapshot) {
                                          final expiry = expirySnapshot.data;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentGreen,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Text(
                                                      'ACTIVE',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (expiry != null)
                                                    Text(
                                                      'Expires: ${expiry.toString().split(' ')[0]}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'You have access to all premium features!',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ] else ...[
                                      const Text(
                                        'Upgrade to Premium to unlock unlimited likes, advanced filters, and more!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => const PremiumSubscriptionScreen(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.star, size: 18),
                                          label: const Text('Upgrade to Premium'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
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
      print('🔍 Attempting to delete image with ID: $imageId');
      print('🔍 Image ID type: ${imageId.runtimeType}');
      
      await ProfileService.deleteImage(imageId);
      print('✅ Image deletion successful');
      
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully!')),
        );
      }
    } catch (error) {
      print('❌ Image deletion failed: $error');
      print('❌ Error type: ${error.runtimeType}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete image: $error')),
        );
      }
    }
  }
} 