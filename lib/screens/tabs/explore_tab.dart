import 'package:flutter/material.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/services/event_service.dart';
import 'package:key_match/services/location_service.dart';
import 'package:key_match/services/match_service.dart';
import 'package:key_match/screens/detailed_profile_screen.dart';
import 'package:key_match/screens/premium_features_screen.dart';
import 'package:key_match/screens/chat_screen.dart';
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
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _suggestion;
  bool _isLoading = true;
  String? _error;
  String? _rawError; // Store the raw error for debugging
  int _currentIndex = 0;
  bool _actionLoading = false;
  // --- Animation state ---
  String _lastAction = 'none'; // 'like', 'dislike', or 'none'
  bool _showActionOverlay = false;
  // --- View mode state ---
  String _viewMode = 'solo'; // 'solo' or 'event'

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
      
      if (_viewMode == 'event') {
        // Load events
        final eventsResponse = await EventService.getEvents(
          status: 'upcoming',
          sortBy: 'distance',
        );

        if (mounted) {
          setState(() {
            _userProfile = profile;
            _events = eventsResponse['success'] == true 
                ? List<Map<String, dynamic>>.from(eventsResponse['events'] ?? [])
                : [];
            _isLoading = false;
            _currentIndex = 0;
          });
        }
      } else {
        // Load potential matches for solo mode
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
      }
    } catch (error) {
      if (mounted) {
        print('🚨 Error loading explore data: $error');
        print('🚨 Error type: ${error.runtimeType}');
        
        // Store raw error for debugging
        String rawError = error.toString();
        
        // Provide more specific error messages based on the error type
        String errorMessage = rawError;
        
        // Check for different types of errors
        if (errorMessage.contains('Profile not found') || errorMessage.contains('404')) {
          errorMessage = 'Welcome! Please complete your profile to start exploring matches.';
        } else if (errorMessage.contains('SocketException') || 
                   errorMessage.contains('Failed host lookup') ||
                   errorMessage.contains('Network is unreachable')) {
          errorMessage = 'Network connection error. Please check your internet connection and try again.';
        } else if (errorMessage.contains('Connection refused') || 
                   errorMessage.contains('Connection timed out')) {
          errorMessage = 'Cannot connect to server. The service may be temporarily unavailable.';
        } else if (errorMessage.contains('401') || errorMessage.contains('403')) {
          errorMessage = 'Authentication error. Please try logging out and back in.';
        } else if (errorMessage.contains('500') || errorMessage.contains('Server error')) {
          errorMessage = 'Server error occurred. Please try again in a few moments.';
        } else if (errorMessage.contains('timeout')) {
          errorMessage = 'Request timed out. Please check your connection and try again.';
        } else {
          // Keep the original error message but make it more user-friendly
          errorMessage = 'Unable to load profiles. ${errorMessage.replaceAll('Exception:', '').replaceAll('Network error:', '').trim()}';
        }
        
        setState(() {
          _error = errorMessage;
          _rawError = rawError;
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
    // Solo mode handling
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
            final matchId = response['matchId'] ?? response['match']?['id'];
            if (matchId != null) {
              _showMatchAlert(currentProfile, matchId);
            }
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
            
            // Premium messages always create a match
            if (response['isMatch'] == true) {
              print('MATCH CREATED! Showing match alert...');
              if (mounted) {
                final matchId = response['matchId'] ?? response['match']?['id'];
                if (matchId != null) {
                  _showMatchAlert(currentProfile, matchId);
                }
              }
            } else {
              // This shouldn't happen with premium messages, but handle it just in case
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

  void _showMatchAlert(Map<String, dynamic> profile, int matchId) {
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
                // Navigate to chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      matchId: matchId.toString(),
                      userName: userName,
                    ),
                  ),
                );
              },
              child: const Text(
                'Start Chatting',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Keep Swiping',
                style: TextStyle(color: Colors.white),
              ),
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

  Widget _buildEventsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          final creator = event['creator'];
          final eventDate = event['eventDate'] != null 
              ? DateTime.parse(event['eventDate'])
              : null;
          final distance = event['distance'];
          final participantCount = event['currentParticipants'] ?? 0;
          final maxParticipants = event['maxParticipants'];
          final userStatus = event['userStatus'];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // TODO: Navigate to event details screen
                _showEventDetailsDialog(event);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event name and status indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event['name'] ?? 'Unnamed Event',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (userStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: userStatus == 'going' 
                                  ? Colors.green 
                                  : userStatus == 'interested'
                                      ? Colors.blue
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userStatus.toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Creator info
                    if (creator != null)
                      Text(
                        'By ${creator['firstName']} ${creator['lastName']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Event details row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        // Date
                        if (eventDate != null)
                          _buildEventInfoChip(
                            Icons.calendar_today,
                            '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                            AppColors.primaryGreen,
                          ),
                        // Time
                        if (event['eventTime'] != null)
                          _buildEventInfoChip(
                            Icons.access_time,
                            event['eventTime'].substring(0, 5),
                            AppColors.primaryGreen,
                          ),
                        // Distance
                        if (distance != null)
                          _buildEventInfoChip(
                            Icons.location_on,
                            '$distance km',
                            AppColors.greenAccent,
                          ),
                        // Participants
                        _buildEventInfoChip(
                          Icons.people,
                          maxParticipants != null 
                              ? '$participantCount/$maxParticipants'
                              : '$participantCount',
                          Colors.blue,
                        ),
                      ],
                    ),
                    // Description
                    if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        event['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsDialog(Map<String, dynamic> event) {
    final creator = event['creator'];
    final eventDate = event['eventDate'] != null 
        ? DateTime.parse(event['eventDate'])
        : null;
    final participantCount = event['currentParticipants'] ?? 0;
    final maxParticipants = event['maxParticipants'];
    final userStatus = event['userStatus'];
    final isParticipating = event['isParticipating'] == true;
    
    // Debug creator check
    print('=== DEBUG EVENT CREATOR CHECK ===');
    print('Creator: $creator');
    print('Creator ID: ${creator?['id']}');
    print('User Profile: $_userProfile');
    print('User Profile userId: ${_userProfile?['userId']}');
    print('User Profile id: ${_userProfile?['id']}');
    print('Event creatorId: ${event['creatorId']}');
    
    final isCreator = creator != null && 
        (creator['id'] == _userProfile?['userId'] || 
         creator['id'] == _userProfile?['id'] ||
         event['creatorId'] == _userProfile?['userId'] ||
         event['creatorId'] == _userProfile?['id']);
    
    print('isCreator: $isCreator');
    print('isParticipating: $isParticipating');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(event['name'] ?? 'Event Details')),
            if (!isParticipating && !isCreator)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final result = await EventService.participateInEvent(
                    eventId: event['id'].toString(),
                    status: 'going',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['success'] == true 
                            ? 'You are now attending this event!'
                            : result['message'] ?? 'Failed to join event'),
                        backgroundColor: result['success'] == true 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    );
                    if (result['success'] == true) {
                      _loadData();
                    }
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Join', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            if (userStatus != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      userStatus == 'going' ? 'Attending' : userStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            if (isCreator)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showEditEventDialog(event);
                },
                tooltip: 'Edit Event',
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Creator
              if (creator != null)
                Text(
                  'Organized by ${creator['firstName']} ${creator['lastName']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 12),
              // Date & Time
              if (eventDate != null)
                _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                ),
              if (event['eventTime'] != null)
                _buildDetailRow(
                  Icons.access_time,
                  'Time',
                  event['eventTime'].substring(0, 5),
                ),
              // Distance
              if (event['distance'] != null)
                _buildDetailRow(
                  Icons.location_on,
                  'Distance',
                  '${event['distance']} km away',
                ),
              // Participants
              _buildDetailRow(
                Icons.people,
                'Participants',
                maxParticipants != null 
                    ? '$participantCount / $maxParticipants'
                    : '$participantCount',
              ),
              // Description
              if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['description'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              // Attendees List
              if (isParticipating || isCreator) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _showAttendeesDialog(event);
                  },
                  icon: const Icon(Icons.people, color: Colors.white),
                  label: Text(
                    'View $participantCount ${participantCount == 1 ? 'attendee' : 'attendees'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Message Creator button (for anyone except the creator themselves)
          if (!isCreator && creator != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showMessageCreatorDialog(event);
              },
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text(
                'Chat with Creator',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (isParticipating && !isCreator)
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await EventService.leaveEvent(
                  event['id'].toString(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['success'] == true 
                          ? 'You have left the event'
                          : result['message'] ?? 'Failed to leave event'),
                      backgroundColor: result['success'] == true 
                          ? Colors.orange 
                          : Colors.red,
                    ),
                  );
                  if (result['success'] == true) {
                    _loadData();
                  }
                }
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Event'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(Map<String, dynamic> event) {
    final TextEditingController nameController = TextEditingController(text: event['name']);
    final TextEditingController descriptionController = TextEditingController(text: event['description'] ?? '');
    DateTime? selectedDate = event['eventDate'] != null ? DateTime.parse(event['eventDate']) : null;
    TimeOfDay? selectedTime;
    
    // Parse existing time if available
    if (event['eventTime'] != null) {
      final timeParts = event['eventTime'].split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.primaryGreen,
          title: Row(
            children: [
              const Icon(Icons.edit, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Edit Event', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'e.g., Coffee Meetup',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.event, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Include location, details, what will happen...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.description, color: Colors.white),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Date',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(Icons.access_time, color: Colors.white),
                        label: Text(
                          selectedTime != null
                              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select Time',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            // Delete button on the left
            TextButton.icon(
              onPressed: () async {
                // Confirm deletion
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Delete Event', style: TextStyle(color: Colors.black87)),
                    content: const Text(
                      'Are you sure you want to delete this event? This action cannot be undone.',
                      style: TextStyle(color: Colors.black87),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  Navigator.of(context).pop(); // Close edit dialog
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deleting event...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Call API to delete event
                  final result = await EventService.deleteEvent(event['id'].toString());
                  
                  if (mounted) {
                    if (result['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event deleted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Failed to delete event'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Delete'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an event name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Updating event...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Call API to update event
                final result = await EventService.updateEvent(
                  eventId: event['id'].toString(),
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty 
                      ? null 
                      : descriptionController.text.trim(),
                  eventDate: selectedDate,
                  eventTime: selectedTime != null 
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'
                      : null,
                );
                
                if (mounted) {
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Failed to update event'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendeesDialog(Map<String, dynamic> event) async {
    // Fetch full event details to get participant list
    final result = await EventService.getEventById(event['id'].toString());
    
    if (result['success'] != true || result['event'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load attendees'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final fullEvent = result['event'];
    final participants = fullEvent['participants'] as List<dynamic>? ?? [];
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.people, color: Colors.white),
            const SizedBox(width: 8),
            Text('Attendees (${participants.length})'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: participants.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No attendees yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    final user = participant['user'];
                    final status = participant['status'] ?? 'interested';
                    final userName = user != null 
                        ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
                        : 'Unknown User';
                    
                    // Debug: Print user data structure
                    print('=== ATTENDEE DEBUG ===');
                    print('User data: $user');
                    if (user != null) {
                      print('User profile: ${user['profile']}');
                      print('User images: ${user['images']}');
                    }
                    
                    // Get profile picture URL
                    String? profilePictureUrl;
                    if (user != null) {
                      // Try to get from user's profile data
                      final userProfile = user['profile'];
                      if (userProfile != null) {
                        // Try profile images first
                        if (userProfile['images'] != null && userProfile['images'].isNotEmpty) {
                          profilePictureUrl = ProfileService.getFullImageUrl(userProfile['images'][0]['imageUrl']);
                        } else if (userProfile['profilePicture'] != null && userProfile['profilePicture'].isNotEmpty) {
                          profilePictureUrl = ProfileService.getFullImageUrl(userProfile['profilePicture']);
                        }
                      }
                      // Fallback to user-level fields
                      if (profilePictureUrl == null) {
                        if (user['images'] != null && user['images'].isNotEmpty) {
                          profilePictureUrl = ProfileService.getFullImageUrl(user['images'][0]['imageUrl']);
                        } else if (user['profilePicture'] != null && user['profilePicture'].isNotEmpty) {
                          profilePictureUrl = ProfileService.getFullImageUrl(user['profilePicture']);
                        }
                      }
                    }
                    
                    final statusIcon = status == 'going' 
                        ? Icons.check_circle
                        : Icons.help_outline;
                    
                    final statusColor = status == 'going'
                        ? Colors.white
                        : Colors.orange;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : null,
                        child: profilePictureUrl == null || profilePictureUrl.isEmpty
                            ? Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        status == 'going' ? 'Going' : 'Maybe',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 20,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvitePeopleDialog(BuildContext context, List<Map<String, dynamic>> matches, Set<int> selectedMatchIds, StateSetter setParentState) {
    print('=== INVITE PEOPLE DEBUG ===');
    print('Total matches: ${matches.length}');
    if (matches.isNotEmpty) {
      print('First match structure: ${matches.first}');
      print('First match profile: ${matches.first['profile']}');
      if (matches.first['profile'] != null) {
        print('First match user: ${matches.first['profile']['user']}');
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.white),
              SizedBox(width: 8),
              Text('Invite People'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: matches.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No matches available to invite',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                          shrinkWrap: true,
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final match = matches[index];
                            final profile = match['profile'];
                            // Try multiple paths to get userId
                            final userId = profile?['user']?['id'] ?? 
                                          profile?['userId'] ??
                                          match['profile']?['user']?['id'];
                            final userName = profile != null && profile['user'] != null
                                ? '${profile['user']['firstName']} ${profile['user']['lastName']}'
                                : 'Unknown';
                            
                            print('Match $index - Checking all paths:');
                            print('  profile[user][id]: ${profile?['user']?['id']}');
                            print('  profile[userId]: ${profile?['userId']}');
                            print('  Final userId: $userId');
                            print('  userName: $userName');
                            
                            if (userId == null) {
                              print('Skipping match $index - userId is null after all attempts');
                              return const SizedBox.shrink();
                            }
                            
                            final isSelected = selectedMatchIds.contains(userId);
                            
                            return CheckboxListTile(
                              dense: true,
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  setParentState(() {
                                    if (value == true) {
                                      selectedMatchIds.add(userId);
                                    } else {
                                      selectedMatchIds.remove(userId);
                                    }
                                  });
                                });
                              },
                              title: Text(
                                userName,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              activeColor: AppColors.primaryGreen,
                              checkColor: Colors.white,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    
    // Load matches for invitation
    List<Map<String, dynamic>> matches = [];
    try {
      matches = await MatchService.getMatches();
    } catch (e) {
      print('Error loading matches: $e');
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        DateTime? selectedDate;
        TimeOfDay? selectedTime;
        bool isPublicEvent = true;
        Set<int> selectedMatchIds = {};
        
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.event_available, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text('Create Event'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    hintText: 'e.g., Coffee Meetup',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.event),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Include location, details, what will happen...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    hintText: 'e.g., 120 (2 hours)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.schedule),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Event Visibility Toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPublicEvent ? Icons.public : Icons.lock,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPublicEvent ? 'Public Event' : 'Private Event',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isPublicEvent 
                                  ? 'Anyone can see and join this event'
                                  : 'Only invited people can see this event',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isPublicEvent,
                        onChanged: (value) {
                          setDialogState(() {
                            isPublicEvent = value;
                          });
                        },
                        thumbColor: WidgetStateProperty.all(Colors.white),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primaryGreen;
                          }
                          return Colors.grey.shade700;
                        }),
                        trackOutlineColor: WidgetStateProperty.all(Colors.white),
                      ),
                    ],
                  ),
                ),
                                  const SizedBox(height: 16),
                  // Invite people button (only for private events)
                  if (!isPublicEvent) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        _showInvitePeopleDialog(context, matches, selectedMatchIds, setDialogState);
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                        selectedMatchIds.isEmpty 
                          ? 'Invite People'
                          : 'Invite People (${selectedMatchIds.length} selected)',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Date',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(Icons.access_time, color: Colors.white),
                        label: Text(
                          selectedTime != null
                              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select Time',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an event name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Creating event...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Call API to create event
                final result = await EventService.createEvent(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty 
                      ? null 
                      : descriptionController.text.trim(),
                  eventDate: selectedDate,
                  eventTime: selectedTime != null 
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'
                      : null,
                  duration: durationController.text.trim().isEmpty 
                      ? null 
                      : int.tryParse(durationController.text.trim()),
                  isPublic: isPublicEvent,
                  invitedUserIds: isPublicEvent ? null : selectedMatchIds.toList(),
                );
                
                if (mounted) {
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Event "${nameController.text}" created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh events list
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Failed to create event'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: _viewMode == 'event'
          ? FloatingActionButton.extended(
              onPressed: () {
                _showCreateEventDialog();
              },
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(
                Icons.event_available,
                color: Colors.white,
              ),
              label: const Text(
                'Create Event',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_viewMode != 'solo') {
                        setState(() {
                          _viewMode = 'solo';
                          _currentIndex = 0;
                        });
                        _loadData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _viewMode == 'solo' 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            color: _viewMode == 'solo' 
                                ? AppColors.primaryGreen 
                                : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Solo',
                            style: TextStyle(
                              color: _viewMode == 'solo' 
                                  ? AppColors.primaryGreen 
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_viewMode != 'event') {
                        setState(() {
                          _viewMode = 'event';
                          _currentIndex = 0;
                        });
                        _loadData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _viewMode == 'event' 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            color: _viewMode == 'event' 
                                ? AppColors.primaryGreen 
                                : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Event',
                            style: TextStyle(
                              color: _viewMode == 'event' 
                                  ? AppColors.primaryGreen 
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _error!.contains('complete your profile') 
                            ? Icons.person_add 
                            : _error!.contains('Network connection') || _error!.contains('connect to server')
                              ? Icons.cloud_off
                              : Icons.error_outline,
                          size: 64,
                          color: _error!.contains('complete your profile') 
                            ? Colors.orange 
                            : Colors.red,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _error!.contains('complete your profile') 
                            ? 'Complete Your Profile'
                            : _error!.contains('Network connection')
                              ? 'Connection Issue'
                              : _error!.contains('connect to server')
                                ? 'Server Unavailable'
                                : 'Error Loading Profiles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _error!.contains('complete your profile') 
                              ? Colors.orange 
                              : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 16,
                            color: _error!.contains('complete your profile') 
                              ? Colors.black87 
                              : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        if (_error!.contains('complete your profile'))
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to profile tab (index 3)
                              widget.navigateToTab(3);
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Go to Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        
                        // Technical details (expandable)
                        if (_rawError != null && _rawError != _error)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ExpansionTile(
                              title: const Text(
                                'Technical Details',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        'Server: ${ApiConfig.baseUrl}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        'Error: $_rawError',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : (_viewMode == 'event' 
                    ? _events.isEmpty 
                    : _potentialMatches.isEmpty || _currentIndex >= _potentialMatches.length)
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
                                Icon(
                                  _viewMode == 'solo' 
                                      ? Icons.person_off 
                                      : Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _viewMode == 'solo' 
                                      ? 'No more solo profiles available!'
                                      : 'No events available yet!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _viewMode == 'solo' 
                                      ? 'Check back later or try adjusting your preferences.'
                                      : 'Check back later for events.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
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
                  : _viewMode == 'event' 
                      ? _buildEventsList()
                      : Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Dismissible(
                                      key: ValueKey('profile_${_potentialMatches[_currentIndex]['id']}'),
                                      direction: DismissDirection.horizontal,
                                      resizeDuration: null, // Prevents "dismissed widget still in tree" error
                                      onDismissed: (direction) {
                                        if (direction == DismissDirection.endToStart) {
                                          // Swiped left = dislike
                                          _handleAction('dislike');
                                        } else if (direction == DismissDirection.startToEnd) {
                                          // Swiped right = like
                                          _handleAction('like');
                                        }
                                      },
                                      background: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 50),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.green.withOpacity(0.8), Colors.transparent],
                                          ),
                                        ),
                                        child: const Icon(Icons.favorite, color: Colors.white, size: 80),
                                      ),
                                      secondaryBackground: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 50),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.transparent, Colors.red.withOpacity(0.8)],
                                          ),
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 80),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => DetailedProfileScreen(
                                                profile: _potentialMatches[_currentIndex],
                                                showActions: true,
                                                onProfileAction: () {
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
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _getUserName(_potentialMatches[_currentIndex]),
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Description Overlay at Bottom
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
                                              // Bio
                                              if (_potentialMatches[_currentIndex]['bio'] != null && 
                                                  _potentialMatches[_currentIndex]['bio'].toString().isNotEmpty)
                                                Text(
                                                  _potentialMatches[_currentIndex]['bio'],
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
                      ),
                        // Action Buttons
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Dislike/Skip Button
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
                              
                              // Like/Request to Join Button
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

  Future<void> _showMessageCreatorDialog(Map<String, dynamic> event) async {
    final creator = event['creator'];
    final creatorName = creator != null 
        ? '${creator['firstName']} ${creator['lastName']}'.trim()
        : 'Event Creator';

    // Get creator's profile picture
    String? creatorProfilePicture;
    if (creator != null) {
      // Try to get from user's profile data
      final creatorProfile = creator['profile'];
      if (creatorProfile != null) {
        // Try profile images first
        if (creatorProfile['images'] != null && creatorProfile['images'].isNotEmpty) {
          creatorProfilePicture = ProfileService.getFullImageUrl(creatorProfile['images'][0]['imageUrl']);
        } else if (creatorProfile['profilePicture'] != null && creatorProfile['profilePicture'].isNotEmpty) {
          creatorProfilePicture = ProfileService.getFullImageUrl(creatorProfile['profilePicture']);
        }
      }
      // Fallback to user-level fields
      if (creatorProfilePicture == null) {
        if (creator['images'] != null && creator['images'].isNotEmpty) {
          creatorProfilePicture = ProfileService.getFullImageUrl(creator['images'][0]['imageUrl']);
        } else if (creator['profilePicture'] != null && creator['profilePicture'].isNotEmpty) {
          creatorProfilePicture = ProfileService.getFullImageUrl(creator['profilePicture']);
        }
      }
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(width: 16),
            Text('Opening chat with $creatorName...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Create match without a message
    final result = await EventService.messageEventCreator(
      eventId: event['id'].toString(),
      message: '', // Empty message - just create the match
    );

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (result['success'] == true) {
        final match = result['match'];
        if (match != null) {
          // Navigate to chat screen with profile picture
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                matchId: match['id'].toString(),
                userName: creatorName,
                userProfilePicture: creatorProfilePicture,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Match created! Check your Messages tab to chat with $creatorName.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create match'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
