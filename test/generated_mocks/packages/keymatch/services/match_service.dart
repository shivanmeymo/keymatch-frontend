import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';  // Re-enabled
import 'auth_service.dart';

class MatchService {
  // Use the same base URL as AuthService
  static String get baseUrl => 'https://key-match-dating-app-a069d14fdf4a.herokuapp.com';

  /// Get all active matches for the current user
  static Future<List<Map<String, dynamic>>> getMyMatches() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/matches'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((match) {
          if (match is Map<String, dynamic>) {
            return match;
          } else {
            print('Warning: Match data is not Map<String, dynamic>: $match');
            return <String, dynamic>{};
          }
        }).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get matches');
      }
    } catch (e) {
      print('Get matches error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get a specific match by ID (with verification)
  static Future<Map<String, dynamic>> getMatch(String matchId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/matches/$matchId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Match not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get match');
      }
    } catch (e) {
      print('Get match error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Verify that the current user has access to a specific match
  static Future<bool> verifyMatchAccess(String matchId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/api/matches/$matchId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Verify match access error: $e');
      return false;
    }
  }

  /// Get messages for a specific match
  static Future<List<Map<String, dynamic>>> getMessages(String matchId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // First verify match access
      final hasAccess = await verifyMatchAccess(matchId);
      if (!hasAccess) {
        throw Exception('You can only view messages from your active matches.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/matches/$matchId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((message) {
          if (message is Map<String, dynamic>) {
            return message;
          } else {
            print('Warning: Message data is not Map<String, dynamic>: $message');
            return <String, dynamic>{};
          }
        }).toList();
      } else if (response.statusCode == 403) {
        throw Exception('You can only view messages from your active matches.');
      } else if (response.statusCode == 404) {
        throw Exception('Match not found. You can only view messages from your own matches.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get messages');
      }
    } catch (e) {
      print('Get messages error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Send a message to a specific match
  static Future<Map<String, dynamic>> sendMessage(String matchId, String content) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Validate message content
      if (content.trim().isEmpty) {
        throw Exception('Message content cannot be empty.');
      }

      if (content.length > 1000) {
        throw Exception('Message content cannot exceed 1000 characters.');
      }

      // First verify match access
      final hasAccess = await verifyMatchAccess(matchId);
      if (!hasAccess) {
        throw Exception('You can only send messages to your active matches.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/matches/$matchId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'content': content.trim(),
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('You can only send messages to your active matches.');
      } else if (response.statusCode == 404) {
        throw Exception('Match not found. You can only message your own matches.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to send message');
      }
    } catch (e) {
      print('Send message error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get matches with last message for the messages tab
  static Future<List<Map<String, dynamic>>> getMatchesWithLastMessage() async {
    try {
      print('🔍 Getting matches with last message...');
      
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      print('🔑 Token obtained: ${token.substring(0, 20)}...');
      print('🌐 Calling API: $baseUrl/api/matches');

      // First get all matches
      final response = await http.get(
        Uri.parse('$baseUrl/api/matches'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> matchesData = json.decode(response.body);
        print('✅ Successfully parsed ${matchesData.length} matches');
        
        // For each match, get the last message
        final List<Map<String, dynamic>> matchesWithLastMessage = [];
        
        for (final match in matchesData) {
          try {
            // Get messages for this match
            final messagesResponse = await http.get(
              Uri.parse('$baseUrl/api/matches/${match['id']}/messages'),
              headers: {
                'Authorization': 'Bearer $token',
              },
            );
            
            Map<String, dynamic> matchWithLastMessage = Map<String, dynamic>.from(match);
            
            if (messagesResponse.statusCode == 200) {
              final List<dynamic> messages = json.decode(messagesResponse.body);
              if (messages.isNotEmpty) {
                // Get the last message (messages are ordered by createdAt ASC)
                final lastMessage = messages.last;
                matchWithLastMessage['lastMessage'] = {
                  'content': lastMessage['content'],
                  'timestamp': lastMessage['timestamp'],
                  'isRead': lastMessage['isRead'],
                };
              } else {
                matchWithLastMessage['lastMessage'] = null;
              }
            } else {
              matchWithLastMessage['lastMessage'] = null;
            }
            
            matchesWithLastMessage.add(matchWithLastMessage);
          } catch (e) {
            print('❌ Error getting messages for match ${match['id']}: $e');
            // Add match without last message
            Map<String, dynamic> matchWithLastMessage = Map<String, dynamic>.from(match);
            matchWithLastMessage['lastMessage'] = null;
            matchesWithLastMessage.add(matchWithLastMessage);
          }
        }
        
        return matchesWithLastMessage;
      } else {
        final errorData = json.decode(response.body);
        print('❌ API Error: $errorData');
        throw Exception(errorData['error'] ?? 'Failed to get matches');
      }
    } catch (e) {
      print('❌ Get matches with last message error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Network error: $e');
    }
  }

  /// Mark messages as read for a specific match
  static Future<void> markMessagesAsRead(String matchId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/api/matches/$matchId/messages/read'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to mark messages as read');
      }
    } catch (e) {
      print('Mark messages as read error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get unread message count for the current user
  static Future<int> getUnreadMessageCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/api/matches/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Get unread message count error: $e');
      return 0;
    }
  }

  /// Get current user's profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/api/profiles/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Get current user profile error: $e');
      return null;
    }
  }
} 