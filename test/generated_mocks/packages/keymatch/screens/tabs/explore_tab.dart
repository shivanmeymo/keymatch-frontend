import 'package:flutter/material.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/screens/detailed_profile_screen.dart';
import 'package:key_match/screens/premium_features_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:key_match/constants/colors.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  _ExploreTabState createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  List<Map<String, dynamic>> _potentialMatches = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _suggestion;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  bool _actionLoading = false;

  // Helper method to get the correct base URL
  String get _baseUrl {
    return 'https://key-match-dating-app-a069d14fdf4a.herokuapp.com';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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
        relationshipType: List<String>.from(_userProfile?['relationshipType'] ?? []),
        keyWords: _userProfile?['keyWords'] != null 
            ? List<String>.from(_userProfile?['keyWords']) 
            : null,
        locationMode: 'global',
        latitude: _userProfile?['latitude'],
        longitude: _userProfile?['longitude'],
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
    });

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
          _actionLoading = false;
        });
      }
    }
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
                                              // Relationship Type
                                              if (_potentialMatches[_currentIndex]['relationshipType'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 8),
                                                  child: Text(
                                                    'Looking for: ${_getRelationshipTypesText(_potentialMatches[_currentIndex]['relationshipType'])}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
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