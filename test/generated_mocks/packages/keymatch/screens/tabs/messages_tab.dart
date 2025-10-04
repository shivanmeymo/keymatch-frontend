import 'package:flutter/material.dart';
import '../../services/match_service.dart';
import '../chat_screen.dart';
import '../detailed_profile_screen.dart';
import '../../constants/colors.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({Key? key}) : super(key: key);

  @override
  _MessagesTabState createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  List<Map<String, dynamic>> _matches = [];
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

      print('🔍 Loading matches...');
      
      // Load matches with last messages using the match service
      final matches = await MatchService.getMatchesWithLastMessage();
      
      print('✅ Matches loaded successfully: ${matches.length} matches');
      print('📋 Matches data: $matches');
      
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading matches: $e');
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
    final userProfilePicture = profile['profilePicture'];
    
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
              : _matches.isEmpty
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
                            'Start swiping to find matches!\nYou can only message people you\'ve matched with.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to explore tab
                              DefaultTabController.of(context)?.animateTo(1);
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
                        itemCount: _matches.length,
                        itemBuilder: (context, index) {
                          final match = _matches[index];
                          final profile = match['profile'];
                          final userName = '${profile['user']['firstName']} ${profile['user']['lastName']}';
                          
                          // Debug profile picture
                          final profilePicture = profile['profilePicture'];
                          print('🔍 Profile picture for $userName: $profilePicture');
                          
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
                                      backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                                          ? NetworkImage(profilePicture)
                                          : null,
                                      child: profilePicture == null || profilePicture.isEmpty
                                          ? const Icon(Icons.person, size: 25, color: Colors.grey)
                                          : null,
                                      onBackgroundImageError: (exception, stackTrace) {
                                        print('❌ Error loading profile picture for $userName: $exception');
                                      },
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
                                          : Colors.grey[600],
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
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 