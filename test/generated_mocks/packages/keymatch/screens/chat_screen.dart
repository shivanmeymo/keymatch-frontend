import 'package:flutter/material.dart';
import '../services/match_service.dart';
import 'detailed_profile_screen.dart';
import '../constants/colors.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String userName;
  final String? userProfilePicture;
  final Map<String, dynamic>? userProfile;

  const ChatScreen({
    Key? key,
    required this.matchId,
    required this.userName,
    this.userProfilePicture,
    this.userProfile,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  int? _currentUserProfileId;
  String _debugInfo = 'Initializing...';

  @override
  void initState() {
    super.initState();
    print('🔍 ChatScreen initState called for match: ${widget.matchId}');
    print('🔍 ChatScreen userName: ${widget.userName}');
    print('🔍 ChatScreen userProfilePicture: ${widget.userProfilePicture}');
    _debugInfo = 'initState called';
    _loadCurrentUserProfile();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      print('🔍 Loading current user profile...');
      _debugInfo = 'Loading current user profile...';
      setState(() {});
      
      final profile = await MatchService.getCurrentUserProfile();
      if (profile != null) {
        _currentUserProfileId = profile['id'];
        print('✅ Current user profile ID: $_currentUserProfileId (type: ${_currentUserProfileId.runtimeType})');
        _debugInfo = 'Profile loaded: $_currentUserProfileId';
        setState(() {});
      } else {
        print('❌ No profile found');
        _debugInfo = 'No profile found';
        setState(() {});
      }
    } catch (e) {
      print('❌ Error loading current user profile: $e');
      _debugInfo = 'Profile error: $e';
      setState(() {});
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _debugInfo = 'Loading messages...';
      });

      print('🔍 Loading messages for match: ${widget.matchId}');

      // Verify match access before loading messages
      _debugInfo = 'Verifying match access...';
      setState(() {});
      
      final hasAccess = await MatchService.verifyMatchAccess(widget.matchId);
      if (!hasAccess) {
        print('❌ No access to match: ${widget.matchId}');
        setState(() {
          _error = 'You can only access messages from your active matches.';
          _isLoading = false;
          _debugInfo = 'No match access';
        });
        return;
      }

      print('✅ Match access verified, loading messages...');
      _debugInfo = 'Loading messages from API...';
      setState(() {});
      
      try {
        final messages = await MatchService.getMessages(widget.matchId);
        print('✅ Messages loaded: ${messages.length} messages');
        print('📋 Messages data: $messages');
        
        // Validate message structure and log detailed info
        for (int i = 0; i < messages.length; i++) {
          try {
            final message = messages[i];
            print('🔍 Validating message $i: $message');
            print('🔍 Message keys: ${message.keys.toList()}');
            
            if (message['sender'] == null) {
              throw Exception('Message $i has no sender');
            }
            
            print('🔍 Sender data: ${message['sender']}');
            print('🔍 Sender keys: ${message['sender'].keys.toList()}');
            
            if (message['sender']['id'] == null) {
              throw Exception('Message $i sender has no ID');
            }
            
            final senderId = message['sender']['id'];
            print('🔍 Sender ID: $senderId (type: ${senderId.runtimeType})');
            
            print('✅ Message $i is valid');
          } catch (e) {
            print('❌ Error validating message $i: $e');
            throw Exception('Invalid message structure at index $i: $e');
          }
        }
        
        setState(() {
          _messages = messages;
          _isLoading = false;
          _debugInfo = 'Messages loaded: ${messages.length}';
        });
      } catch (e) {
        print('❌ Error in getMessages API call: $e');
        print('❌ Error type: ${e.runtimeType}');
        setState(() {
          _error = 'API Error: $e';
          _isLoading = false;
          _debugInfo = 'API Error: $e';
        });
        return;
      }

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('❌ Error loading messages: $e');
      print('❌ Error type: ${e.runtimeType}');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _debugInfo = 'Error: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    try {
      setState(() {
        _isSending = true;
      });

      // Verify match access before sending message
      final hasAccess = await MatchService.verifyMatchAccess(widget.matchId);
      if (!hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only send messages to your active matches.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newMessage = await MatchService.sendMessage(widget.matchId, message);
      
      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
        _isSending = false;
      });

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSending = false;
      });
    }
  }

  String _formatTimestamp(String timestamp) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (widget.userProfile != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedProfileScreen(
                    profile: widget.userProfile!,
                    showActions: false,
                  ),
                ),
              );
            }
          },
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.userProfilePicture != null
                        ? NetworkImage(widget.userProfilePicture!)
                        : null,
                    child: widget.userProfilePicture == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  // Small indicator that profile is clickable
                  if (widget.userProfile != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          size: 8,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Active Match',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.userProfile != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailedProfileScreen(
                      profile: widget.userProfile!,
                      showActions: false,
                    ),
                  ),
                );
              },
              tooltip: 'View Profile',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
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
                            'Error loading messages',
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
                            onPressed: _loadMessages,
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
                  : Column(
                      children: [
                        Expanded(
                          child: _messages.isEmpty
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
                                        'No messages yet',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Start a conversation with ${widget.userName}!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadMessages,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      try {
                                        final message = _messages[index];
                                        print('🔍 Processing message $index: $message');
                                        print('🔍 Message sender: ${message['sender']}');
                                        print('🔍 Current user profile ID: $_currentUserProfileId (type: ${_currentUserProfileId.runtimeType})');
                                        
                                        // Add null checks
                                        if (message['sender'] == null) {
                                          print('❌ Message $index has no sender');
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            child: const Text(
                                              'Error: Invalid message format',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          );
                                        }
                                        
                                        final senderId = message['sender']['id'];
                                        if (senderId == null) {
                                          print('❌ Message $index sender has no ID');
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            child: const Text(
                                              'Error: Invalid sender format',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          );
                                        }
                                        
                                        print('🔍 Sender ID: $senderId (type: ${senderId.runtimeType})');
                                        
                                        final isMyMessage = _currentUserProfileId != null && 
                                            senderId.toString() == _currentUserProfileId.toString();
                                        
                                        print('🔍 Is my message: $isMyMessage');
                                        
                                        return Align(
                                          alignment: isMyMessage 
                                              ? Alignment.centerRight 
                                              : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMyMessage 
                                                  ? AppColors.tintColorLight
                                                  : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message['content'],
                                                  style: TextStyle(
                                                    color: isMyMessage 
                                                        ? Colors.white 
                                                        : Colors.black,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatTimestamp(message['timestamp']),
                                                  style: TextStyle(
                                                    color: isMyMessage 
                                                        ? Colors.white70 
                                                        : Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        print('❌ Error processing message $index: $e');
                                        _debugInfo = 'Message error: $e';
                                        setState(() {});
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Error loading message: $e',
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, -1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(25)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  maxLines: null,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.tintColorLight,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: _isSending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.send, color: Colors.white),
                                  onPressed: _isSending ? null : _sendMessage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          // Debug overlay - always show for debugging
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info:',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _debugInfo,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  if (_error != null)
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  if (_isLoading)
                    const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.yellow, fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 