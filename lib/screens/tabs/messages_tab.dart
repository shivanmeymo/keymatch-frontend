import 'package:flutter/material.dart';
import '../../services/match_service.dart';
import '../../services/profile_service.dart';
import '../chat_screen.dart';
import '../detailed_profile_screen.dart';
import '../../constants/colors.dart';

class MessagesTab extends StatefulWidget {
  final Function(int) navigateToTab;

  const MessagesTab({Key? key, required this.navigateToTab}) : super(key: key);

  @override
  _MessagesTabState createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _pendingMessages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 Loading matches and pending messages...');
      
      // Load active matches and pending messages
      final matches = await MatchService.getMatchesWithLastMessage();
      final pendingMessages = await MatchService.getPendingMessages();
      
      print('✅ Matches loaded successfully: ${matches.length} matches');
      print('✅ Pending messages loaded successfully: ${pendingMessages.length} pending');
      
      setState(() {
        _matches = matches;
        _pendingMessages = pendingMessages;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading data: $e');
      print('❌ Error type: ${e.runtimeType}');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _navigateToChat(Map<String, dynamic> match) {
    final profile = match['profile'];
    final userName = '${profile['user']['firstName']} ${profile['user']['lastName']}';
    final userProfilePicture = ProfileService.getFullImageUrl(profile['profilePicture']);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchId: match['id'].toString(),
          userName: userName,
          userProfilePicture: userProfilePicture,
          userProfile: profile,
        ),
      ),
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _unmatchUser(Map<String, dynamic> match) async {
    try {
      final matchId = match['id'].toString();
      final profile = match['profile'];
      final userName = '${profile['user']['firstName']} ${profile['user']['lastName']}';
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unmatch User'),
          content: Text('Are you sure you want to unmatch with $userName? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unmatch'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // Call the unmatch API
        await MatchService.unmatchUser(matchId);
        
        // Remove the match from the local list
        setState(() {
          _matches.removeWhere((m) => m['id'].toString() == matchId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unmatched with $userName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unmatch: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Messages',
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
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Error loading matches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _loadMatches,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tintColorLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : _matches.isEmpty && _pendingMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No matches yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Start swiping to find matches!\nPremium messages will appear here while waiting for a response.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to explore tab (index 1)
                              widget.navigateToTab(1);
                            },
                            icon: const Icon(Icons.explore),
                            label: const Text('Start Exploring'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tintColorLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatches,
                      child: ListView.builder(
                        itemCount: _matches.length + _pendingMessages.length,
                        itemBuilder: (context, index) {
                          if (index < _matches.length) {
                            final match = _matches[index];
                            final profile = match['profile'];
                            final userName = '${profile['user']['firstName']} ${profile['user']['lastName']}';
                            
                            // Get profile picture with full URL
                            String? profilePictureUrl;
                            if (profile['images'] != null && profile['images'].isNotEmpty) {
                              profilePictureUrl = ProfileService.getFullImageUrl(profile['images'][0]['imageUrl']);
                            } else if (profile['profilePicture'] != null) {
                              profilePictureUrl = ProfileService.getFullImageUrl(profile['profilePicture']);
                            }
                            
                            print('🔍 Profile picture for $userName: $profilePictureUrl');
                            
                            // Handle lastMessage properly - it's an object, not a string
                            String lastMessageText = 'Start a conversation!';
                            String lastMessageTime = '';
                            
                            if (match['lastMessage'] != null) {
                              final lastMessage = match['lastMessage'];
                              lastMessageText = lastMessage['content'] ?? 'Start a conversation!';
                              lastMessageTime = _formatTimestamp(lastMessage['timestamp']);
                            }
                            
                            final unreadCount = match['unreadCount'] ?? 0;
                            final hasUnread = unreadCount > 0;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: GestureDetector(
                                  onTap: () {
                                    // Navigate to detailed profile screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailedProfileScreen(
                                          profile: profile,
                                          showActions: false,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: _isValidImageUrl(profilePictureUrl)
                                            ? NetworkImage(profilePictureUrl!)
                                            : null,
                                        child: !_isValidImageUrl(profilePictureUrl)
                                            ? const Icon(Icons.person, size: 25, color: Colors.grey)
                                            : null,
                                      ),
                                      // Small indicator that profile is clickable
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: AppColors.tintColorLight,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: hasUnread 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (hasUnread)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.tintColorLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lastMessageText,
                                      style: TextStyle(
                                        color: hasUnread 
                                            ? Colors.black 
                                            : Colors.grey[200],
                                        fontWeight: hasUnread 
                                            ? FontWeight.w500 
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (lastMessageTime.isNotEmpty)
                                      Text(
                                        lastMessageTime,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => _navigateToChat(match),
                                onLongPress: () {
                                  // Show options menu for the match
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.person),
                                            title: const Text('View Profile'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => DetailedProfileScreen(
                                                    profile: profile,
                                                    showActions: false,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.message),
                                            title: const Text('Send Message'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _navigateToChat(match);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.block),
                                            title: const Text('Unmatch'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _unmatchUser(match);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            final pendingMessage = _pendingMessages[index - _matches.length];
                            final profile = pendingMessage['profile'];
                            final userName = '${profile['user']['firstName']} ${profile['user']['lastName']}';
                            final userProfilePicture = profile['profilePicture'];

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: GestureDetector(
                                  onTap: () {
                                    // Navigate to detailed profile screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailedProfileScreen(
                                          profile: profile,
                                          showActions: false,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: _isValidImageUrl(userProfilePicture)
                                            ? NetworkImage(userProfilePicture)
                                            : null,
                                        child: !_isValidImageUrl(userProfilePicture)
                                            ? const Icon(Icons.person, size: 25, color: Colors.grey)
                                            : null,
                                      ),
                                      // Small indicator that profile is clickable
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: AppColors.tintColorLight,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pendingMessage['lastMessage'] != null 
                                        ? pendingMessage['lastMessage']['content'] ?? 'Premium message sent - waiting for response'
                                        : 'Premium message sent - waiting for response',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Tap to view profile',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to detailed profile screen for pending messages
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailedProfileScreen(
                                        profile: profile,
                                        showActions: false,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () {
                                  // Show options menu for the pending message
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.person),
                                            title: const Text('View Profile'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => DetailedProfileScreen(
                                                    profile: profile,
                                                    showActions: false,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.block),
                                            title: const Text('Unmatch'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _unmatchUser(pendingMessage);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
    );
  }
} 