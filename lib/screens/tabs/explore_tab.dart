import 'package:flutter/material.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/screens/detailed_profile_screen.dart';
import 'package:key_match/screens/premium_features_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:key_match/constants/colors.dart';
import '../../constants/api_config.dart';

class ExploreTab extends StatefulWidget {
  final Function(int) navigateToTab;

  const ExploreTab({Key? key, required this.navigateToTab}) : super(key: key);

  @override
  _ExploreTabState createState() => _ExploreTabState();

  // Helper method to get the correct base URL
  String get _baseUrl {
    return ApiConfig.baseUrl;
  }
}

class _ExploreTabState extends State<ExploreTab> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _potentialMatches = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _suggestion;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  bool _actionLoading = false;
  // --- Animation state ---
  String _lastAction = 'none'; // 'like', 'dislike', or 'none'
  bool _showActionOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app becomes visible again
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load user profile
      final profile = await ProfileService.getProfile();
      
      // Load potential matches, passing gender preference if available
      final matchesResponse = await ProfileService.getPotentialMatches(
        genderPreference: profile?['genderPreference'],
      );

      if (mounted) {
        setState(() {
          _userProfile = profile;
          
          // Safely convert profiles data
          final profilesData = matchesResponse['profiles'];
          print('🔍 Explore tab - matchesResponse type: ${matchesResponse.runtimeType}');
          print('🔍 Explore tab - profilesData type: ${profilesData.runtimeType}');
          print('🔍 Explore tab - profilesData: $profilesData');
          
          if (profilesData is List) {
            _potentialMatches = profilesData.map((profile) {
              if (profile is Map<String, dynamic>) {
                return profile;
              } else {
                print('⚠️ Warning: Profile data is not Map<String, dynamic>: $profile');
                print('⚠️ Profile type: ${profile.runtimeType}');
                return <String, dynamic>{};
              }
            }).toList();
          } else {
            print('⚠️ Warning: profiles data is not a List: $profilesData');
            _potentialMatches = [];
          }
          
          print('🔍 Explore tab - _potentialMatches length: ${_potentialMatches.length}');
          _suggestion = matchesResponse['suggestion'];
          _isLoading = false;
          _currentIndex = 0;
        });
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

  // Method to refresh data when returning to explore tab
  Future<void> _refreshData() async {
    print('🔄 Refreshing explore tab data...');
    await _loadData();
  }

  Future<void> _enableGlobalMode() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update user's location mode to global
      await ProfileService.updateProfile(
        bio: _userProfile?['bio'] ?? '',
        birthDate: _userProfile?['birthDate'],
        gender: _userProfile?['gender'] ?? '',
        genderPreference: _userProfile?['genderPreference'] ?? '',
        location: _userProfile?['location'],
        relationshipType: _userProfile?['relationshipType'] ?? 'C',
      );

      // Reload data with global mode
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Global mode enabled! You can now see profiles worldwide.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enable global mode: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAction(String actionType) async {
    if (_currentIndex >= _potentialMatches.length) return;
    if (_actionLoading) return;

    setState(() {
      _actionLoading = true;
      _lastAction = actionType;
      _showActionOverlay = true;
    });

    // Wait for fade animation
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final currentProfile = _potentialMatches[_currentIndex];
      print('Current profile: $currentProfile');
      print('Profile ID: ${currentProfile['id']}');

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
                    child: const Text(
                      'Maybe Later',
                      style: TextStyle(color: Colors.white),
                    ),
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
            _showActionOverlay = false;
            _actionLoading = false;
          });
          return;
        }

        // Use the like feature (increment counter only for non-premium users)
        await PremiumService.useFeature('unlimited_likes');
        
        final response = await ProfileService.likeProfile(currentProfile['id'].toString());
        print('Like response: $response');
        print('Response type: ${response.runtimeType}');
        print('isMatch value: ${response['isMatch']}');
        print('isMatch type: ${response['isMatch'].runtimeType}');
        
        // Check if it's a match
        if (response['isMatch'] == true) {
          print('MATCH DETECTED! Showing match alert...');
          if (mounted) {
            _showMatchAlert(currentProfile);
          }
          // Store match_id for future chat functionality
          if (response['match_id'] != null) {
            print('Match ID: ${response['match_id']}');
            // TODO: Store match_id in shared preferences or state management
          }
        } else {
          print('No match - just a regular like');
        }
        
        // Move to next profile after like, regardless of match
        setState(() {
          _currentIndex++;
        });
      } else if (actionType == 'dislike') {
        // Dislikes never count toward the like limit - they're always allowed
        print('Processing dislike - no premium check needed');
        
        // Call the dislike endpoint
        await ProfileService.dislikeProfile(currentProfile['id'].toString());
        
        // Move to next profile after dislike
        setState(() {
          _currentIndex++;
        });
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
              currentProfile['id'].toString(),
              message.trim(),
            );
            
            print('Like with message response: $response');
            
            // Check if it's a match
            if (response['isMatch'] == true) {
              print('MATCH DETECTED! Showing match alert...');
              if (mounted) {
                _showMatchAlert(currentProfile);
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message sent and profile liked!')),
                );
              }
            }
            
            // Move to next profile after sending message
            setState(() {
              _currentIndex++;
            });
          }
        }
      }
    } catch (error) {
      print('Error $actionType profile: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $actionType profile. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _showActionOverlay = false;
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

  void _showMatchAlert(Map<String, dynamic> profile) {
    final userName = _getUserName(profile);
    
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
                // TODO: Navigate to chat with match_id
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat functionality coming soon!')),
                );
              },
              child: const Text('Start Chatting'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Keep Swiping'),
            ),
          ],
        );
      },
    );
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

  String _getProfileImageUrl(Map<String, dynamic> profile) {
    // First try to get from images array
    if (profile['images'] != null && profile['images'].isNotEmpty) {
      final imageUrl = profile['images'][0]['imageUrl'];
      // Use the centralized method from ProfileService
      return ProfileService.getFullImageUrl(imageUrl);
    }
    
    // Fallback to profilePicture
    if (profile['profilePicture'] != null && profile['profilePicture'].isNotEmpty) {
      final imageUrl = profile['profilePicture'];
      return ProfileService.getFullImageUrl(imageUrl);
    }
    
    return '';
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading profiles...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Error loading data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _potentialMatches.isEmpty || _currentIndex >= _potentialMatches.length
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_suggestion != null && _suggestion!['type'] == 'enable_global_mode')
                            Column(
                              children: [
                                const Icon(
                                  Icons.location_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _suggestion!['message'] ?? 'No matches found in your area.',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => _enableGlobalMode(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.greenAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('Enable Global Mode'),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _loadData,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                const Text(
                                  'No more profiles to show.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DetailedProfileScreen(
                                      profile: _potentialMatches[_currentIndex],
                                      showActions: true,
                                      onProfileAction: () {
                                        // Refresh data when returning from detailed profile
                                        _loadData();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: cardWidth,
                                height: cardWidth * 1.3,
                                margin: const EdgeInsets.only(top: 20),
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
                                  child: Stack(
                                    children: [
                                      // Profile Image
                                      Positioned.fill(
                                        child: _getProfileImageUrl(_potentialMatches[_currentIndex]).isNotEmpty
                                            ? Image.network(
                                                _getProfileImageUrl(_potentialMatches[_currentIndex]),
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
                                              )
                                            : Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 100,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                      // --- Heart/Cross Overlay Animation ---
                                      if (_showActionOverlay && _lastAction == 'like')
                                        Center(
                                          child: AnimatedOpacity(
                                            opacity: _showActionOverlay ? 1.0 : 0.0,
                                            duration: const Duration(milliseconds: 300),
                                            child: Icon(Icons.favorite, color: Colors.green, size: 160),
                                          ),
                                        ),
                                      if (_showActionOverlay && _lastAction == 'dislike')
                                        Center(
                                          child: AnimatedOpacity(
                                            opacity: _showActionOverlay ? 1.0 : 0.0,
                                            duration: const Duration(milliseconds: 300),
                                            child: Icon(Icons.close, color: Colors.red, size: 160),
                                          ),
                                        ),
                                      // Name Overlay at Top
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.8),
                                                Colors.transparent,
                                              ],
                                            ),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(15),
                                              topRight: Radius.circular(15),
                                            ),
                                          ),
                                          child: Text(
                                            _getUserName(_potentialMatches[_currentIndex]),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Bio Overlay at Bottom
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
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(15),
                                              bottomRight: Radius.circular(15),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Age and Relationship Type Row
                                              Row(
                                                children: [
                                                  // Age
                                                  if (_potentialMatches[_currentIndex]['age'] != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '${_potentialMatches[_currentIndex]['age']} years old',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  if (_potentialMatches[_currentIndex]['age'] != null)
                                                    const SizedBox(width: 8),
                                                  // Relationship Type
                                                  if (_potentialMatches[_currentIndex]['relationshipType'] != null)
                                                    Expanded(
                                                      child: Text(
                                                        'Looking for: ${_getRelationshipTypesText(_potentialMatches[_currentIndex]['relationshipType'])}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Bio
                                              Text(
                                                _potentialMatches[_currentIndex]['bio'] ?? 'No bio available',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Action Buttons
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Dislike Button
                              GestureDetector(
                                onTap: _actionLoading ? null : () => _handleAction('dislike'),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(40),
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
                                    size: 36,
                                  ),
                                ),
                              ),
                              
                              // Send Message Button (Premium feature)
                              FutureBuilder<bool>(
                                future: PremiumService.isFeatureAvailable('like_by_message'),
                                builder: (context, snapshot) {
                                  final canSendMessage = snapshot.data ?? false;
                                  
                                  if (canSendMessage) {
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
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(40),
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
                                    size: 36,
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
} 