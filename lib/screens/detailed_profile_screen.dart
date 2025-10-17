import 'package:flutter/material.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/constants/colors.dart';
import 'package:key_match/screens/premium_features_screen.dart';
import 'package:key_match/widgets/enhanced_keyword_display.dart';

class DetailedProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final bool showActions;
  final VoidCallback? onProfileAction; // Callback to notify parent of action

  const DetailedProfileScreen({
    Key? key,
    required this.profile,
    this.showActions = true,
    this.onProfileAction,
  }) : super(key: key);

  @override
  _DetailedProfileScreenState createState() => _DetailedProfileScreenState();
}

class _DetailedProfileScreenState extends State<DetailedProfileScreen> {
  bool _actionLoading = false;
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getUserName(Map<String, dynamic> profile) {
    if (profile['user'] != null) {
      final user = profile['user'];
      if (user['firstName'] != null && user['lastName'] != null) {
        return '${user['firstName']} ${user['lastName']}'.trim();
      } else if (user['username'] != null) {
        return user['username'];
      } else if (user['firstName'] != null) {
        return user['firstName'];
      }
    }
    return 'Unknown';
  }

  List<String> _getAllImages(Map<String, dynamic> profile) {
    List<String> imageUrls = [];
    
    // Debug logging
    print('=== DEBUG: _getAllImages ===');
    print('Profile keys: ${profile.keys.toList()}');
    print('Profile images: ${profile['images']}');
    print('Profile profilePicture: ${profile['profilePicture']}');
    
    // Prioritize the 'images' array if it exists and is not empty
    if (profile['images'] != null && profile['images'].isNotEmpty) {
      print('Found images array with ${profile['images'].length} images');
      for (var image in profile['images']) {
        print('Processing image: $image');
        // Assuming profile['images'] is already sorted by the backend
        // and the first image is the primary one.
        if (image['imageUrl'] != null && image['imageUrl'].isNotEmpty) {
          final fullUrl = ProfileService.getFullImageUrl(image['imageUrl']);
          print('Adding image URL: $fullUrl');
          imageUrls.add(fullUrl);
        } else {
          print('Skipping image with empty URL: $image');
        }
      }
    } else if (profile['profilePicture'] != null && profile['profilePicture'].isNotEmpty) {
      // Fallback to profilePicture only if 'images' array is missing or empty
      print('Using profilePicture fallback: ${profile['profilePicture']}');
      final fullUrl = ProfileService.getFullImageUrl(profile['profilePicture']);
      print('Adding profilePicture URL: $fullUrl');
      imageUrls.add(fullUrl);
    } else {
      print('No images found in profile');
    }
    
    print('Final image URLs: $imageUrls');
    return imageUrls;
  }

  Future<void> _handleAction(String actionType) async {
    if (_actionLoading) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      if (actionType == 'like') {
        // Check if user can like (premium feature check)
        final canLike = await PremiumService.isFeatureAvailable('unlimited_likes');
        
        if (!canLike) {
          // Show premium upgrade dialog
          if (mounted) {
            final shouldUpgrade = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Like Limit Reached'),
                content: const Text(
                  'You\'ve used all your free likes for today. Upgrade to Premium for unlimited likes!',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Maybe Later'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Premium'),
                  ),
                ],
              ),
            );
            
            if (shouldUpgrade == true) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumFeaturesScreen(),
                ),
              );
            }
          }
          setState(() {
            _actionLoading = false;
          });
          return;
        }

        // Use the feature (increment counter only for non-premium users)
        await PremiumService.useFeature('unlimited_likes');
        
        final response = await ProfileService.likeProfile(widget.profile['id'].toString());
        
        if (response['isMatch'] == true) {
          if (mounted) {
            _showMatchAlert();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile liked!')),
            );
          }
        }
      } else if (actionType == 'send_message') {
        // Check if user has premium for like by message feature
        final canSendMessage = await PremiumService.isFeatureAvailable('like_by_message');
        
        if (!canSendMessage) {
          // Show premium upgrade dialog
          if (mounted) {
            final shouldUpgrade = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Premium Feature'),
                content: const Text(
                  'Send messages with likes is a premium feature. Upgrade to Premium to use this feature!',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Maybe Later'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Premium'),
                  ),
                ],
              ),
            );
            
            if (shouldUpgrade == true) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumFeaturesScreen(),
                ),
              );
            }
          }
          return;
        }

        // Show message input dialog
        if (mounted) {
          final message = await _showMessageInputDialog();
          if (message != null && message.trim().isNotEmpty) {
            final response = await ProfileService.likeProfileWithMessage(
              widget.profile['id'].toString(),
              message.trim(),
            );
            
            if (response['isMatch'] == true) {
              if (mounted) {
                _showMatchAlert();
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message sent and profile liked!')),
                );
              }
            }
            
            // Navigate back after sending message
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      } else {
        await ProfileService.dislikeProfile(widget.profile['id'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile passed')),
          );
        }
      }
      
      // Navigate back after action (except for send_message which handles its own navigation)
      if (mounted && actionType != 'send_message') {
        // Notify parent that an action was performed
        widget.onProfileAction?.call();
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $actionType profile. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<String?> _showMessageInputDialog() async {
    final TextEditingController messageController = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send a message and automatically like this profile',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Write your message...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final message = messageController.text.trim();
              if (message.isNotEmpty) {
                Navigator.of(context).pop(message);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showMatchAlert() {
    final userName = _getUserName(widget.profile);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("It's a Match! 🎉"),
          content: Text("You matched with $userName!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                // TODO: Navigate to chat
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat functionality coming soon!')),
                );
              },
              child: const Text('Start Chatting'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Keep Browsing'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('=== DEBUG: DetailedProfileScreen build ===');
    print('Profile data: ${widget.profile}');
    final allImages = _getAllImages(widget.profile);
    print('All images count: ${allImages.length}');
    print('All images URLs: $allImages');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Remove info button for photo gallery
        // actions: [ ... ]
      ),
      body: Column(
        children: [
          // Image Gallery Section at the top
          if (allImages.isNotEmpty) ...[
            Container(
              height: 300,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        allImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allImages.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPageIndex ? AppColors.primaryGreen : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Details Section (no image gallery)
                  // Basic Info
                  if (widget.profile['age'] != null)
                    _buildInfoRow('Age', '${widget.profile['age']} years old'),
                  if (widget.profile['gender'] != null)
                    _buildInfoRow('Gender', _getGenderText(widget.profile['gender'])),
                  if (widget.profile['location'] != null)
                    _buildInfoRow('Location', widget.profile['location']),
                  if (widget.profile['locationMode'] != null)
                    _buildInfoRow('Mode', _getLocationModeDisplay(widget.profile['locationMode'])),
                  const SizedBox(height: 20),
                  // Name Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getUserName(widget.profile),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  // Relationship Type Section
                  if (widget.profile['relationshipType'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Looking for',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getRelationshipTypesText(widget.profile['relationshipType']),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  // Bio Section
                  if (widget.profile['bio'] != null && widget.profile['bio'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.profile['bio'],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  // Key Words Section
                  if (widget.profile['keyWords'] != null && 
                      widget.profile['keyWords'] is List && 
                      (widget.profile['keyWords'] as List).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Key Words',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        EnhancedKeywordDisplay(
                          keywords: List<String>.from(
                            (widget.profile['keyWords'] as List).map((keyword) => keyword.toString())
                          ),
                          isEditing: false,
                          initialDisplayCount: 20,
                          maxHeight: 200,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Action Buttons (if enabled)
          if (widget.showActions)
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Dislike Button
                  GestureDetector(
                    onTap: _actionLoading ? null : () => _handleAction('dislike'),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  
                  // Message Button (Premium only)
                  FutureBuilder<bool>(
                    future: PremiumService.isPremium(),
                    builder: (context, snapshot) {
                      final isPremium = snapshot.data ?? false;
                      
                      if (isPremium) {
                        return GestureDetector(
                          onTap: _actionLoading ? null : () => _handleAction('send_message'),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.amber[600],
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chat_bubble,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  
                  // Like Button
                  GestureDetector(
                    onTap: _actionLoading ? null : () => _handleAction('like'),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationModeDisplay(String mode) {
    switch (mode.toLowerCase()) {
      case 'local':
        return 'Local';
      case 'global':
        return 'Global';
      default:
        return mode;
    }
  }

  String _getRelationshipTypeText(String? type) {
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
} 