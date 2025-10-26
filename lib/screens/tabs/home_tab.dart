import 'package:flutter/material.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/ai_service.dart';
import 'dart:convert';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/screens/detailed_profile_screen.dart';
import 'package:key_match/constants/colors.dart';
import 'package:http/http.dart' as http;

class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? keywords;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.keywords,
  });
}

class HomeTab extends StatefulWidget {
  final Function(int) navigateToTab;

  const HomeTab({Key? key, required this.navigateToTab}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Message> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _limitReached = false;
  String _limitMessage = '';
  String? _userProfilePicture;
  Map<String, dynamic>? _messageUsage;

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
    _loadUserProfile(); // Load user profile picture
    _loadMessageUsage(); // Load message usage
    
    // Add welcome message if no history
    // I'm like that friend who really wants to get to know you and then introduce you to people who could be perfect for you.\n\n
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messages.isEmpty) {
        setState(() {
                  _messages.add(Message(
          id: 'welcome',
          text: "Hey there! 👋 I'm so excited to help you find amazing connections! \n\nI can get to know you better by suggesting keywords that might fit your profile, and then find people who share your interests and values.\n\nTry telling me something about yourself! 😊",
          isUser: false,
          timestamp: DateTime.now(),
          keywords: null,
        ));
        });
      }
      
      // Force refresh profile picture after initial build
      _refreshProfilePicture();
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
      // Check if user has a complete profile before loading AI chat history
      final profile = await ProfileService.getCompleteProfile();
      if (profile == null) {
        print('No complete profile found, skipping AI chat history load');
        return;
      }
      
      final history = await KeyMakerService.getConversationHistory();
      if (history.isNotEmpty) {
        setState(() {
          _messages = history.map((msg) {
            final content = msg['content'] ?? '';
            final isUser = msg['isUser'] ?? false;
            
            // For AI messages, extract keywords and clean the display text
            if (!isUser) {
              final extractedKeywords = KeyMakerService.extractKeywordsFromResponse(content);
              String displayText = content;
              if (extractedKeywords.isNotEmpty) {
                // Remove the <keywords>...</keywords> tags from the display text
                displayText = content.replaceAll(RegExp(r'<keywords>.*?</keywords>', caseSensitive: false), '').trim();
              }
              
              return Message(
                id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                text: displayText,
                isUser: isUser,
                timestamp: DateTime.parse(msg['timestamp'] ?? DateTime.now().toIso8601String()),
                keywords: extractedKeywords.isNotEmpty ? extractedKeywords : null,
              );
            } else {
              // For user messages, just use the content as-is
              return Message(
                id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                text: content,
                isUser: isUser,
                timestamp: DateTime.parse(msg['timestamp'] ?? DateTime.now().toIso8601String()),
                keywords: null,
              );
            }
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading conversation history: $e');
      // Continue without history if there's an error
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      print('🔍 Loading user profile for AI chat...');
      final profile = await ProfileService.getProfile();
      print('🔍 Profile loaded: ${profile != null}');
      if (profile != null) {
        print('🔍 Profile keys: ${profile.keys.toList()}');
        print('🔍 Profile data: $profile');
        
        // Use the same logic as profile tab - check images array first
        String? profilePictureUrl;
        
        if (profile['images'] != null && profile['images'] is List && profile['images'].isNotEmpty) {
          print('🔍 Found ${profile['images'].length} images in profile');
          
          // Find the primary image first
          final primaryImage = profile['images'].firstWhere(
            (image) => image['isPrimary'] == true,
            orElse: () => profile['images'][0], // Fallback to first image
          );
          
          print('🔍 Selected image: $primaryImage');
          String? imageUrl = primaryImage['imageUrl'];
          print('🔍 Extracted imageUrl: $imageUrl');
          
          if (imageUrl != null) {
            profilePictureUrl = imageUrl;
            print('🔍 Using image from images array: $profilePictureUrl');
          }
        }
        
        // Fallback to profilePicture if no image from images array
        if (profilePictureUrl == null && profile['profilePicture'] != null) {
          profilePictureUrl = profile['profilePicture'];
          print('🔍 Using profilePicture fallback: $profilePictureUrl');
        }
        
        if (profilePictureUrl != null) {
          setState(() {
            _userProfilePicture = profilePictureUrl;
          });
          print('✅ User profile picture set: "$_userProfilePicture" (type: ${_userProfilePicture.runtimeType})');
          print('🔍 Is valid URL: ${_isValidUserImageUrl(_userProfilePicture)}');
        } else {
          print('❌ No profile picture found in profile');
          print('🔍 Available profile fields: ${profile.keys.toList()}');
          
          // Check if there are images in the profile
          if (profile['images'] != null && profile['images'] is List) {
            print('🔍 Found ${profile['images'].length} images in profile');
            for (int i = 0; i < profile['images'].length; i++) {
              print('🔍 Image $i: ${profile['images'][i]}');
            }
          }
        }
      } else {
        print('❌ Profile is null');
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
      print('❌ Error type: ${e.runtimeType}');
    }
  }

  Future<void> _loadMessageUsage() async {
    try {
      final usage = await KeyMakerService.getMessageUsage();
      setState(() {
        _messageUsage = usage;
      });
      print('✅ Message usage loaded: $_messageUsage');
    } catch (e) {
      print('❌ Error loading message usage: $e');
    }
  }

  Future<void> _refreshProfilePicture() async {
    print('🔍 Force refreshing profile picture...');
    await _loadUserProfile();
    if (mounted) {
      setState(() {
        // Force rebuild to show updated profile picture
      });
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
    final message = _inputController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _limitReached = false;
      _limitMessage = '';
    });

    _inputController.clear();

    // Add user message to the list
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
      keywords: null,
    );

    setState(() {
      _messages.add(userMessage);
    });

    _scrollToBottom();

    try {
      // Check if user has a complete profile before sending AI message
      final profile = await ProfileService.getCompleteProfile();
      if (profile == null) {
        setState(() {
          _messages.add(Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: "Please complete your profile setup first before using the AI chat feature.",
            isUser: false,
            timestamp: DateTime.now(),
            keywords: null,
          ));
        });
        return;
      }

      final response = await KeyMakerService.sendMessage(message);
      
      print('📩 AI response received: $response');
      print('📩 Response length: ${response.length}');
      print('📩 Response type: ${response.runtimeType}');
      
      // Extract keywords from AI response
      final extractedKeywords = KeyMakerService.extractKeywordsFromResponse(response);
      print('📩 Extracted keywords result: $extractedKeywords');
      print('📩 Extracted keywords length: ${extractedKeywords.length}');
      
      // Remove keyword tags from the response text for display
      String displayText = response;
      if (extractedKeywords.isNotEmpty) {
        // Remove the <keywords>...</keywords> tags from the display text
        displayText = response.replaceAll(RegExp(r'<keywords>.*?</keywords>', caseSensitive: false), '').trim();
      }
      
      setState(() {
        final newMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: displayText,
          isUser: false,
          timestamp: DateTime.now(),
          keywords: extractedKeywords, // Store keywords with the message
        );
        _messages.add(newMessage);
        print('🔍 Created message with keywords: ${newMessage.keywords}');
        print('🔍 Message text: ${newMessage.text}');
      });
      
      _scrollToBottom();
      
      print('🔍 Extracted keywords: $extractedKeywords');
      if (extractedKeywords.isNotEmpty) {
        print('✅ Keywords found and attached to message');
      } else {
        print('❌ No keywords extracted from response');
      }
      
      // Refresh message usage after sending
      _loadMessageUsage();
    } on KeyMakerMessageLimitException catch (e) {
      setState(() {
        _limitReached = true;
        _limitMessage = e.message;
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: "You've reached your daily message limit. Upgrade to premium for unlimited messages!",
          isUser: false,
          timestamp: DateTime.now(),
          keywords: null,
        ));
      });
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: "Sorry, I'm having trouble connecting right now. Please try again later.",
          isUser: false,
          timestamp: DateTime.now(),
          keywords: null,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  // Helper function to extract suggested keywords from AI messages
  List<String> _extractSuggestedKeywords(String text) {
    // Look for patterns like "Suggested keywords: keyword1, keyword2, keyword3"
    final regex = RegExp(r'Suggested keywords:\s*([\w\s,\-]+)', caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null) {
      return match.group(1)!
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
    }
    
    // Also look for numbered lists like "1. Hiking, Photography, Adventurous"
    final numberedRegex = RegExp(r'\d+\.\s*([\w\s,\-]+)', caseSensitive: false);
    final numberedMatches = numberedRegex.allMatches(text);
    if (numberedMatches.isNotEmpty) {
      final keywords = <String>[];
      for (final match in numberedMatches) {
        final keywordGroup = match.group(1)!;
        final keywordList = keywordGroup
            .split(',')
            .map((k) => k.trim())
            .where((k) => k.isNotEmpty)
            .toList();
        keywords.addAll(keywordList);
      }
      return keywords;
    }
    
    // Look for patterns like "keywords like keyword1, keyword2, keyword3"
    final likeRegex = RegExp(r'keywords like\s*([\w\s,\-]+)', caseSensitive: false);
    final likeMatch = likeRegex.firstMatch(text);
    if (likeMatch != null) {
      return likeMatch.group(1)!
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
    }
    
    return [];
  }

  // Dialog functionality removed as requested - no popup when chatting with AI

  // Update user keywords using the new API endpoint
  Future<void> _updateUserKeywords(List<String> keywords) async {
    try {
      await KeyMakerService.updateKeywords(keywords);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${keywords.length} keywords to your profile!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      print('Error updating keywords: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update keywords: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to add keyword to user's profile
  Future<void> _addKeywordToProfile(String keyword) async {
    try {
      // Get current profile
      final profile = await ProfileService.getCompleteProfile();
      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found')),
        );
        return;
      }

      // Get current keywords
      List<String> currentKeywords = [];
      if (profile['keyWords'] != null) {
        if (profile['keyWords'] is List) {
          currentKeywords = List<String>.from(profile['keyWords']);
        } else if (profile['keyWords'] is String) {
          currentKeywords = [profile['keyWords']];
        }
      }

      // Check if keyword already exists
      if (currentKeywords.contains(keyword)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$keyword" is already in your profile')),
        );
        return;
      }

      // Add new keyword
      currentKeywords.add(keyword);

      // Get current profile data to pass required parameters
      final currentProfile = await ProfileService.getCompleteProfile();
      if (currentProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found')),
        );
        return;
      }

      // Extract required parameters from current profile
      final genderPreference = currentProfile['genderPreference'] ?? 'B';
      List<String> relationshipType;
      if (currentProfile['relationshipType'] is List) {
        relationshipType = (currentProfile['relationshipType'] as List)
            .map((item) => item.toString())
            .toList();
      } else {
        relationshipType = [currentProfile['relationshipType']?.toString() ?? 'C'];
      }

      // Update profile with new keywords
      await ProfileService.updateProfile(
        keyWords: currentKeywords,
        genderPreference: genderPreference,
        relationshipType: relationshipType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$keyword" to your profile')),
      );
      
      // Refresh the UI to update keyword chip colors
      setState(() {});
    } catch (e) {
      print('Error adding keyword to profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add keyword: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_limitReached)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _limitMessage,
                            style: TextStyle(color: Colors.orange[800], fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to premium screen
                             widget.navigateToTab(3); // Assuming 3 is the premium tab index
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Upgrade',
                            style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        enabled: !_limitReached,
                        decoration: InputDecoration(
                          hintText: _limitReached ? 'Message limit reached' : 'Ask for matches or start a conversation...',
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
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          fillColor: _limitReached ? Colors.grey[200] : Colors.white,
                          filled: true,
                          hintStyle: TextStyle(
                            color: _limitReached 
                                ? Colors.grey[600] 
                                : AppColors.textSecondaryLight.withOpacity(0.7),
                          ),
                        ),
                        style: TextStyle(
                          color: _limitReached ? Colors.grey[600] : AppColors.textPrimaryLight,
                          fontSize: 16,
                        ),
                        maxLines: null,
                        maxLength: 250,
                        buildCounter: (BuildContext context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // AI Message Counter - positioned at the far left
                              if (_messageUsage != null && 
                                  _messageUsage!['remainingMessages'] != null && 
                                  _messageUsage!['dailyLimit'] != null) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_messageUsage!['remainingMessages']}/${_messageUsage!['dailyLimit']}',
                                      style: TextStyle(
                                        color: _messageUsage!['isPremium'] == true 
                                            ? AppColors.accentGreen 
                                            : AppColors.primaryGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_messageUsage!['remainingMessages'] == 0) ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          widget.navigateToTab(3); // Navigate to premium tab
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Upgrade',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ] else ...[
                                // Show loading or default state when message usage is not available
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '5/5',
                                      style: TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Character counter - positioned at the far right
                              Text(
                                '$currentLength/$maxLength',
                                style: TextStyle(
                                  color: AppColors.textPrimaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                        onSubmitted: _limitReached || _isLoading ? null : (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _limitReached || _isLoading ? Colors.grey : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: _limitReached || _isLoading ? null : _sendMessage,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
        print('🔍 Attempting to parse AI response as JSON: ${message.text.substring(0, 100)}...');
        
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
            } else {
              print('⚠️ JSON found but not in expected format. Type: ${data['type']}, Profiles: ${data['profiles']}');
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
        } else {
          print('⚠️ Entire response is JSON but not in expected format. Type: ${data['type']}, Profiles: ${data['profiles']}');
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
                    // Display keyword chips if this is an AI message with suggested keywords
                    if (message.keywords != null && message.keywords!.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Suggested keywords:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: message.keywords!.map((keyword) {
                              return ActionChip(
                                label: Text(
                                  keyword,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppColors.accentGreenLight,
                                labelStyle: const TextStyle(color: Colors.white),
                                onPressed: () => _addKeywordToProfile(keyword),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
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
                  // Display keyword chips if this is an AI message with suggested keywords
                  Builder(
                    builder: (context) {
                      print('🔍 Checking message for keywords: ${message.keywords}');
                      print('🔍 Message isUser: $isUser');
                      print('🔍 Message keywords not null: ${message.keywords != null}');
                      print('🔍 Message keywords not empty: ${message.keywords?.isNotEmpty}');
                      
                      if (!isUser && message.keywords != null && message.keywords!.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Suggested keywords:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<Map<String, dynamic>?>(
                              future: ProfileService.getCompleteProfile(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                
                                final profile = snapshot.data;
                                List<String> userKeywords = [];
                                if (profile != null && profile['keyWords'] != null) {
                                  if (profile['keyWords'] is List) {
                                    userKeywords = List<String>.from(profile['keyWords']);
                                  } else if (profile['keyWords'] is String) {
                                    userKeywords = [profile['keyWords']];
                                  }
                                }
                                
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: message.keywords!.map((keyword) {
                                    final isAlreadyAdded = userKeywords.contains(keyword);
                                    return ActionChip(
                                      label: Text(
                                        keyword,
                                        style: TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w500,
                                          color: isAlreadyAdded ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      backgroundColor: isAlreadyAdded ? Colors.amber[600] : Colors.grey[300],
                                      onPressed: () => _addKeywordToProfile(keyword),
                                      elevation: 2,
                                      pressElevation: 4,
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
            Builder(
              builder: (context) {
                print('🔍 Building user avatar with profile picture: "$_userProfilePicture"');
                print('🔍 Is valid URL: ${_isValidUserImageUrl(_userProfilePicture)}');
                return CircleAvatar(
                  radius: 24,
                  backgroundImage: _isValidUserImageUrl(_userProfilePicture)
                      ? NetworkImage(_userProfilePicture!)
                      : null,
                  child: !_isValidUserImageUrl(_userProfilePicture)
                      ? const Icon(Icons.person, color: Colors.grey, size: 20)
                      : null,
                  onBackgroundImageError: _isValidUserImageUrl(_userProfilePicture)
                      ? (exception, stackTrace) {
                          print('❌ Error loading user profile picture in AI chat: $exception');
                          print('❌ User profile picture URL: "$_userProfilePicture"');
                          print('❌ Stack trace: $stackTrace');
                          // Don't call setState here as it can cause issues in this context
                          // The error will be handled by the child fallback
                        }
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  bool _isValidUserImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      print('❌ Error parsing URL "$url": $e');
      return false;
    }
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
    final name = (profile['user']?['firstName'] ?? '') + ' ' + (profile['user']?['lastName'] ?? '');
    final age = profile['age'] != null ? ', ${profile['age']} yrs' : '';
    final photoUrl = profile['profilePicture'] ?? '';
    print('🔍 Profile picture URL: "$photoUrl" (type: ${photoUrl.runtimeType})');
    final hasError = profile['error'] == true;
    
    return InkWell(
      onTap: () => Navigator.push(context, 
        MaterialPageRoute(builder: (_) => DetailedProfileScreen(profile: profile))
      ),
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
              backgroundImage: _isValidImageUrl(photoUrl) ? NetworkImage(photoUrl) : null,
              child: !_isValidImageUrl(photoUrl) ? const Icon(Icons.person, size: 24) : null,
              onBackgroundImageError: _isValidImageUrl(photoUrl)
                  ? (exception, stackTrace) {
                      print('❌ Error loading profile picture: $exception');
                      print('❌ URL that failed: "$photoUrl"');
                      print('❌ Stack trace: $stackTrace');
                      // The error will be handled by the child fallback
                      // No need to call setState as the child will show the fallback icon
                    }
                  : null,
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
                      color: hasError ? Colors.red[700] : Colors.black,
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