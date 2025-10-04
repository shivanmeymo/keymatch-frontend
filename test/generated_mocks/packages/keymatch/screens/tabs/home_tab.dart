import 'package:flutter/material.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/ai_service.dart';
import 'dart:convert';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/screens/detailed_profile_screen.dart';
import 'package:key_match/constants/colors.dart';

class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Message> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
    
    // Add welcome message if no history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(Message(
            id: 'welcome',
            text: "Hi! I'm your KeyMatch AI assistant. I can help you find your perfect match through an interactive conversation!\n\n💚 **How it works:**\n• Ask me to find matches and I'll ask you a few questions\n• I'll use your answers to find the most compatible person\n• I'll show you exactly why they're a great match for you\n\nTry saying:\n• 'Show me some potential matches'\n• 'Find someone who likes outdoor activities'\n• 'I'm looking for a serious relationship'\n\nWhat would you like to explore?",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationHistory() async {
    try {
      final history = await KeyMakerService.getConversationHistory();
      if (history.isNotEmpty) {
        setState(() {
          _messages = history.map((msg) => Message(
            id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            text: msg['content'] ?? '',
            isUser: msg['isUser'] ?? false,
            timestamp: DateTime.parse(msg['timestamp'] ?? DateTime.now().toIso8601String()),
          )).toList();
        });
      }
    } catch (e) {
      print('Error loading conversation history: $e');
      // Continue without history if there's an error
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      // Convert messages to history format for AI
      final history = _messages.map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      }).toList();

      final aiResponse = await KeyMakerService.sendMessage(text, history: history);
      
      final aiMessage = Message(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMessage);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $error')),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $error')),
        );
      }
    }
  }

  Future<void> _clearChat() async {
    try {
      await KeyMakerService.clearConversationHistory();
      setState(() {
        _messages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear chat: $error')),
      );
    }
  }

  Future<void> _sendTestMessage() async {
    _inputController.text = "Show me some potential matches";
    await _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'KeyMatch',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages Container
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  // Loading indicator
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Input Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Ask for matches or start a conversation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    maxLength: 500,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
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

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    
    // Check if this is an AI question (contains numbered questions or asks for preferences)
    final isAIQuestion = !isUser && (
      message.text.contains(RegExp(r'\d+\.')) || // Contains numbered list
      message.text.toLowerCase().contains('question') ||
      message.text.toLowerCase().contains('what type') ||
      message.text.toLowerCase().contains('what are your') ||
      message.text.toLowerCase().contains('are there any') ||
      message.text.toLowerCase().contains('to give you the best')
    );
    
    // Try to parse as AI profile list JSON
    if (!isUser) {
      try {
        // First, try to find JSON in the response (in case AI includes text + JSON)
        String responseText = message.text;
        
        // Look for JSON object in the response
        final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(responseText);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0);
          if (jsonString != null) {
            print('🔍 Found potential JSON in AI response: $jsonString');
            
            final data = json.decode(jsonString);
            if (data is Map<String, dynamic> && data['type'] == 'profile_list' && data['profiles'] is List) {
              print('✅ Successfully parsed profile list JSON with ${data['profiles'].length} profiles');
              return _ProfileListBubble(
                profileIds: List<String>.from(data['profiles'].map((p) => p['id'].toString())),
                explanation: data['explanation'] as String?,
                timestamp: message.timestamp,
              );
            }
          }
        }
        
        // If no JSON found, try parsing the entire response as JSON
        final data = json.decode(responseText);
        if (data is Map<String, dynamic> && data['type'] == 'profile_list' && data['profiles'] is List) {
          print('✅ Successfully parsed entire response as profile list JSON');
          return _ProfileListBubble(
            profileIds: List<String>.from(data['profiles'].map((p) => p['id'].toString())),
            explanation: data['explanation'] as String?,
            timestamp: message.timestamp,
          );
        }
      } catch (e) {
        print('❌ Failed to parse AI response as JSON: $e');
        print('🔍 AI response text: ${message.text}');
      }
    }
    
    // Special styling for AI questions
    if (isAIQuestion) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreenLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: AppColors.accentGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Finding your perfect match...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Fallback: normal text bubble
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryGreen : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: !isUser ? Border.all(color: AppColors.primaryGreenLightest) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser ? Colors.white70 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

// Widget to display a list of profiles in a chat bubble
class _ProfileListBubble extends StatefulWidget {
  final List<String> profileIds;
  final String? explanation;
  final DateTime timestamp;
  const _ProfileListBubble({required this.profileIds, required this.explanation, required this.timestamp});
  @override
  State<_ProfileListBubble> createState() => _ProfileListBubbleState();
}

class _ProfileListBubbleState extends State<_ProfileListBubble> {
  late Future<List<Map<String, dynamic>>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _fetchProfiles();
  }

  Future<List<Map<String, dynamic>>> _fetchProfiles() async {
    final List<Map<String, dynamic>> profiles = [];
    print('🔍 Fetching ${widget.profileIds.length} profiles: ${widget.profileIds}');
    
    for (final id in widget.profileIds) {
      try {
        print('🔍 Fetching profile with ID: $id');
        final profile = await ProfileService.getProfileById(id);
        print('✅ Successfully fetched profile: ${profile['user']?['firstName']} ${profile['user']?['lastName']}');
        profiles.add(profile);
      } catch (e) {
        print('❌ Failed to fetch profile with ID $id: $e');
        // Add a placeholder profile to show the error
        profiles.add({
          'id': id,
          'user': {
            'firstName': 'Unknown',
            'lastName': 'User',
          },
          'bio': 'Profile not available',
          'error': true,
        });
      }
    }
    
    print('🔍 Total profiles fetched: ${profiles.length}');
    return profiles;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreenLightest),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _profilesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text('Failed to load profiles', style: TextStyle(color: Colors.red));
                      }
                      final profiles = snapshot.data ?? [];
                      if (profiles.isEmpty) {
                        return const Text('No profiles found.');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.explanation != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreenLightest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGreenLighter),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, color: AppColors.primaryGreen, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Why this match?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.explanation!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimaryLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Text(
                            'Potential Match:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          ...profiles.map((profile) => _ProfileListRow(profile: profile)),
                          const SizedBox(height: 8),
                          Text(
                            _formatTime(widget.timestamp),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class _ProfileListRow extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileListRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = (profile['user']?['firstName'] ?? '') + ' ' + (profile['user']?['lastName'] ?? '');
    final age = profile['age'] != null ? ', ${profile['age']} yrs' : '';
    final photoUrl = profile['profilePicture'] ?? '';
    final hasError = profile['error'] == true;
    
    return InkWell(
      onTap: hasError ? null : () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailedProfileScreen(profile: profile),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasError ? Colors.red[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasError ? Colors.red[300]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty ? const Icon(Icons.person, size: 24) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.trim().isEmpty ? 'Unknown' : name.trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: hasError ? Colors.red[700] : null,
                    ),
                  ),
                  if (hasError)
                    Text(
                      'Profile not available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            if (age.isNotEmpty && !hasError)
              Text(age, style: const TextStyle(fontSize: 15, color: Colors.grey)),
            if (!hasError)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
} 