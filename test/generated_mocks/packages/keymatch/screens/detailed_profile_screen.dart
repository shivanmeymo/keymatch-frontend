import 'package:flutter/material.dart';
import 'package:key_match/services/profile_service.dart';

class DetailedProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final bool showActions;

  const DetailedProfileScreen({
    Key? key,
    required this.profile,
    this.showActions = true,
  }) : super(key: key);

  @override
  _DetailedProfileScreenState createState() => _DetailedProfileScreenState();
}

class _DetailedProfileScreenState extends State<DetailedProfileScreen> {
  bool _actionLoading = false;
  int _currentImageIndex = 0;

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

  String _getProfileImageUrl(Map<String, dynamic> profile, int index) {
    // First try to get from images array
    if (profile['images'] != null && profile['images'].isNotEmpty) {
      if (index < profile['images'].length) {
        final imageUrl = profile['images'][index]['imageUrl'];
        return ProfileService.getFullImageUrl(imageUrl);
      }
    }
    
    // Fallback to profilePicture for first image
    if (index == 0 && profile['profilePicture'] != null && profile['profilePicture'].isNotEmpty) {
      final imageUrl = profile['profilePicture'];
      return ProfileService.getFullImageUrl(imageUrl);
    }
    
    return '';
  }

  List<String> _getAllImages(Map<String, dynamic> profile) {
    List<String> images = [];
    
    // Add profile picture if available
    if (profile['profilePicture'] != null && profile['profilePicture'].isNotEmpty) {
      images.add(ProfileService.getFullImageUrl(profile['profilePicture']));
    }
    
    // Add images from images array
    if (profile['images'] != null && profile['images'].isNotEmpty) {
      for (var image in profile['images']) {
        if (image['imageUrl'] != null && image['imageUrl'].isNotEmpty) {
          images.add(ProfileService.getFullImageUrl(image['imageUrl']));
        }
      }
    }
    
    return images;
  }

  Future<void> _handleAction(String actionType) async {
    if (_actionLoading) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      if (actionType == 'like') {
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
      } else {
        await ProfileService.dislikeProfile(widget.profile['id'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile passed')),
          );
        }
      }
      
      // Navigate back after action
      if (mounted) {
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
    final allImages = _getAllImages(widget.profile);
    final hasMultipleImages = allImages.length > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (hasMultipleImages)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Photo Gallery'),
                    content: Text('Swipe left/right to view all ${allImages.length} photos'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Image Gallery Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              child: Stack(
                children: [
                  // Main Image
                  PageView.builder(
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: allImages.isNotEmpty ? allImages.length : 1,
                    itemBuilder: (context, index) {
                      if (allImages.isNotEmpty) {
                        return Image.network(
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
                        );
                      } else {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.grey,
                          ),
                        );
                      }
                    },
                  ),
                  
                  // Image Counter
                  if (hasMultipleImages)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${allImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Gradient Overlay for Name
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        _getUserName(widget.profile),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Profile Details Section
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  if (widget.profile['age'] != null)
                    _buildInfoRow('Age', '${widget.profile['age']} years old'),
                  
                  if (widget.profile['gender'] != null)
                    _buildInfoRow('Gender', widget.profile['gender']),
                  
                  if (widget.profile['location'] != null)
                    _buildInfoRow('Location', widget.profile['location']),
                  
                  if (widget.profile['locationMode'] != null)
                    _buildInfoRow('Mode', _getLocationModeDisplay(widget.profile['locationMode'])),
                  
                  const SizedBox(height: 20),
                  
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getRelationshipTypesText(widget.profile['relationshipType']),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.profile['bio'],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
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
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (widget.profile['keyWords'] as List)
                              .map((keyword) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      keyword.toString(),
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  
                  // Photos Count
                  if (allImages.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${allImages.length} photo${allImages.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
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
} 