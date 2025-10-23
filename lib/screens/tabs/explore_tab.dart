import 'package:flutter/material.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/services/event_service.dart';
import 'package:key_match/services/location_service.dart';
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
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _suggestion;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  bool _actionLoading = false;
  // --- Animation state ---
  String _lastAction = 'none'; // 'like', 'dislike', or 'none'
  bool _showActionOverlay = false;
  // --- View mode state ---
  String _viewMode = 'solo'; // 'solo', 'group', or 'event'

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
        // Load potential matches for solo/group mode
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Location
                    if (event['location'] != null && event['location'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event['location'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
    final isCreator = creator != null && creator['id'] == _userProfile?['userId'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(event['name'] ?? 'Event Details')),
            if (isCreator)
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.primaryGreen),
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
              // Location
              if (event['location'] != null)
                _buildDetailRow(
                  Icons.place,
                  'Location',
                  event['location'],
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
              // Current status
              if (userStatus != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'You are ${userStatus == 'going' ? 'attending' : userStatus}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!isParticipating)
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
              icon: const Icon(Icons.check),
              label: const Text('Join Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            )
          else
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
            child: const Text('Close'),
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
    final TextEditingController locationController = TextEditingController(text: event['location'] ?? '');
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
    
    double? eventLatitude = event['latitude'] != null ? double.tryParse(event['latitude'].toString()) : null;
    double? eventLongitude = event['longitude'] != null ? double.tryParse(event['longitude'].toString()) : null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text('Edit Event'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update your event details',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
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
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What will happen at this event?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          hintText: 'Enter address or place name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        try {
                          final location = await LocationService.getCurrentLocation();
                          if (location != null) {
                            setState(() {
                              eventLatitude = location['latitude'];
                              eventLongitude = location['longitude'];
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Current location set'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to get location: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.my_location, color: AppColors.textPrimaryLight),
                      tooltip: 'Use current GPS location',
                    ),
                  ],
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
                            setState(() => selectedDate = date);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimaryLight,
                          side: BorderSide(color: AppColors.textPrimaryLight),
                        ),
                        icon: Icon(Icons.calendar_today, color: AppColors.textPrimaryLight),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Date',
                          style: TextStyle(color: AppColors.textPrimaryLight),
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
                            setState(() => selectedTime = time);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimaryLight,
                          side: BorderSide(color: AppColors.textPrimaryLight),
                        ),
                        icon: Icon(Icons.access_time, color: AppColors.textPrimaryLight),
                        label: Text(
                          selectedTime != null
                              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select Time',
                          style: TextStyle(color: AppColors.textPrimaryLight),
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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimaryLight,
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
                  location: locationController.text.trim().isEmpty 
                      ? null 
                      : locationController.text.trim(),
                  latitude: eventLatitude,
                  longitude: eventLongitude,
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
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.group_add, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('Create Group'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a group to connect with multiple people who share similar interests.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g., Hiking Enthusiasts',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.label),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this group about?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimaryLight,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a group name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // TODO: Call API to create group
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Group "${nameController.text}" created! (Coming soon)'),
                  backgroundColor: Colors.green,
                ),
              );
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
  }

  void _showCreateEventDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    double? eventLatitude;
    double? eventLongitude;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                const Text(
                  'Organize an event and invite people to join!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
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
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'What will happen at this event?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          hintText: 'Enter address or place name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        try {
                          final location = await LocationService.getCurrentLocation();
                          if (location != null) {
                            setState(() {
                              eventLatitude = location['latitude'];
                              eventLongitude = location['longitude'];
                            });
                            // Show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Current location set'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to get location: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.my_location, color: AppColors.textPrimaryLight),
                      tooltip: 'Use current GPS location',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                            setState(() => selectedDate = date);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimaryLight,
                          side: BorderSide(color: AppColors.textPrimaryLight),
                        ),
                        icon: Icon(Icons.calendar_today, color: AppColors.textPrimaryLight),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Date',
                          style: TextStyle(color: AppColors.textPrimaryLight),
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
                            setState(() => selectedTime = time);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimaryLight,
                          side: BorderSide(color: AppColors.textPrimaryLight),
                        ),
                        icon: Icon(Icons.access_time, color: AppColors.textPrimaryLight),
                        label: Text(
                          selectedTime != null
                              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select Time',
                          style: TextStyle(color: AppColors.textPrimaryLight),
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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimaryLight,
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
                  location: locationController.text.trim().isEmpty 
                      ? null 
                      : locationController.text.trim(),
                  latitude: eventLatitude,
                  longitude: eventLongitude,
                  eventDate: selectedDate,
                  eventTime: selectedTime != null 
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'
                      : null,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: _viewMode != 'solo'
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_viewMode == 'group') {
                  _showCreateGroupDialog();
                } else if (_viewMode == 'event') {
                  _showCreateEventDialog();
                }
              },
              backgroundColor: AppColors.primaryGreen,
              icon: Icon(
                _viewMode == 'group' ? Icons.group_add : Icons.event_available,
                color: Colors.white,
              ),
              label: Text(
                _viewMode == 'group' ? 'Create Group' : 'Create Event',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
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
                      if (_viewMode != 'group') {
                        setState(() {
                          _viewMode = 'group';
                          _currentIndex = 0;
                        });
                        _loadData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _viewMode == 'group' 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups,
                            color: _viewMode == 'group' 
                                ? AppColors.primaryGreen 
                                : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Group',
                            style: TextStyle(
                              color: _viewMode == 'group' 
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
                                      : _viewMode == 'group'
                                          ? Icons.group_off
                                          : Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _viewMode == 'solo' 
                                      ? 'No more solo profiles available!'
                                      : _viewMode == 'group'
                                          ? 'No group profiles available yet!'
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
                                      : _viewMode == 'group'
                                          ? 'Group matching coming soon! Try Solo mode.'
                                          : 'Event matching coming soon! Try Solo mode.',
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
                                              // Age, Distance and Relationship Type Row
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
                                                  // Distance (if available in local mode)
                                                  if (_potentialMatches[_currentIndex]['distance'] != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryGreen.withOpacity(0.7),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.location_on,
                                                            size: 14,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${_potentialMatches[_currentIndex]['distance']} km',
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (_potentialMatches[_currentIndex]['distance'] != null)
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
                                              // Matching Keywords
                                              if (_potentialMatches[_currentIndex]['matchingKeywords'] != null && 
                                                  (_potentialMatches[_currentIndex]['matchingKeywords'] as List).isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: (_potentialMatches[_currentIndex]['matchingKeywords'] as List)
                                                      .take(5) // Show max 5 matching keywords
                                                      .map((keyword) => Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.greenAccent.withOpacity(0.9),
                                                              borderRadius: BorderRadius.circular(15),
                                                              border: Border.all(
                                                                color: Colors.white.withOpacity(0.3),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(
                                                                  Icons.check_circle,
                                                                  size: 14,
                                                                  color: Colors.white,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  keyword.toString(),
                                                                  style: const TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ))
                                                      .toList(),
                                                ),
                                              ],
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