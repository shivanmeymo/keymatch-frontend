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

  @override
  void initState() {
    super.initState();
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
      final profile = await MatchService.getCompleteProfile();
      if (profile != null) {
        _currentUserProfileId = profile['id'];
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Verify match access before loading messages
      final hasAccess = await MatchService.verifyMatchAccess(widget.matchId);
      if (!hasAccess) {
        setState(() {
          _error = 'You can only access messages from your active matches.';
          _isLoading = false;
        });
        return;
      }

      try {
        final messages = await MatchService.getMessages(widget.matchId);
        
        // Validate message structure
        for (int i = 0; i < messages.length; i++) {
          try {
            final message = messages[i];
            
            if (message['sender'] == null) {
              throw Exception('Message $i has no sender');
            }
            
            if (message['sender']['id'] == null) {
              throw Exception('Message $i sender has no ID');
            }
          } catch (e) {
            throw Exception('Invalid message structure at index $i: $e');
          }
        }
        
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'API Error: $e';
          _isLoading = false;
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
      setState(() {
        _error = e.toString();
        _isLoading = false;
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

  Future<void> _unmatchUser() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unmatch User'),
          content: Text('Are you sure you want to unmatch with ${widget.userName}? This action cannot be undone and you will no longer be able to message each other.'),
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
        await MatchService.unmatchUser(widget.matchId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unmatched with ${widget.userName}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to messages tab
          Navigator.of(context).pop();
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

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
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
                    backgroundImage: _isValidImageUrl(widget.userProfilePicture)
                        ? NetworkImage(widget.userProfilePicture!)
                        : null,
                    child: !_isValidImageUrl(widget.userProfilePicture)
                        ? const Icon(Icons.person, size: 18)
                        : null,
                    onBackgroundImageError: _isValidImageUrl(widget.userProfilePicture)
                        ? (exception, stackTrace) {
                            print('❌ Error loading chat profile picture: $exception');
                            // The error will be handled by the child fallback
                          }
                        : null,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh Messages',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'unmatch') {
                _unmatchUser();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'unmatch',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Unmatch'),
                  ],
                ),
              ),
            ],
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
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(25)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(25)),
                                      borderSide: BorderSide(color: AppColors.primaryGreenLightest),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(25)),
                                      borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    fillColor: Colors.white, // Pure white background
                                    filled: true,
                                    hintStyle: TextStyle(
                                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: AppColors.textPrimaryLight,
                                    fontSize: 16,
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
        ],
      ),
    );
  }
} 