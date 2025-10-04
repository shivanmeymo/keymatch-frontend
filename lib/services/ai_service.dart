import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

class KeyMakerMessageLimitException implements Exception {
  final String message;
  KeyMakerMessageLimitException(this.message);
  @override
  String toString() => 'KeyMakerMessageLimitException: $message';
}

class KeyMakerService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Send a message to the key maker and get a response
  static Future<String> sendMessage(String message) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      print('🤖 Sending AI message: $message');

      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message,
        }),
      );

      print('🤖 AI response status: ${response.statusCode}');
      print('🤖 AI response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['response'] ?? 'Sorry, I couldn\'t process your message.';
        print('🤖 AI response text: $aiResponse');
        return aiResponse;
      } else if (response.statusCode == 429) {
        final errorData = json.decode(response.body);
        print('🤖 AI Message limit reached: ${errorData['error']}');
        throw KeyMakerMessageLimitException(errorData['error'] ?? 'Message limit reached for today. Upgrade to premium for unlimited messages.');
      } else {
        final errorData = json.decode(response.body);
        print('🤖 AI error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to get key maker response');
      }
    } catch (e) {
      print('Key maker service error: $e');
      if (e is KeyMakerMessageLimitException) {
        rethrow;
      }
      throw Exception('Failed to get key maker response: $e');
    }
  }

  /// Update user keywords based on AI suggestions
  static Future<Map<String, dynamic>> updateKeywords(List<String> keywords) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      print('🤖 Updating keywords: $keywords');

      final response = await http.post(
        Uri.parse('$baseUrl/ai/update-keywords'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'keywords': keywords,
        }),
      );

      print('🤖 Update keywords response status: ${response.statusCode}');
      print('🤖 Update keywords response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🤖 Keywords updated successfully');
        return data;
      } else {
        final errorData = json.decode(response.body);
        print('🤖 Update keywords error: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to update keywords');
      }
    } catch (e) {
      print('Update keywords service error: $e');
      throw Exception('Failed to update keywords: $e');
    }
  }

  /// Get conversation history for the current user
  static Future<List<Map<String, dynamic>>> getConversationHistory() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/ai/conversation-history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get conversation history');
      }
    } catch (e) {
      print('Get conversation history error: $e');
      throw Exception('Failed to get conversation history: $e');
    }
  }

  /// Clear conversation history
  static Future<void> clearConversationHistory() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse('$baseUrl/ai/conversation-history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to clear conversation history');
      }
    } catch (e) {
      print('Clear conversation history error: $e');
      throw Exception('Failed to clear conversation history: $e');
    }
  }

  /// Get AI message usage for current user
  static Future<Map<String, dynamic>> getMessageUsage() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/ai/usage'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get message usage');
      }
    } catch (e) {
      print('Get message usage error: $e');
      throw Exception('Failed to get message usage: $e');
    }
  }

  /// Extract keywords from AI response
  static List<String> extractKeywordsFromResponse(String response) {
    try {
      print('🔍 Extracting keywords from response: ${response.substring(0, 100)}...');
      
      // Look for the special <keywords> tag
      final keywordTagPattern = RegExp(r'<keywords>(.*?)</keywords>', caseSensitive: false);
      final match = keywordTagPattern.firstMatch(response);
      
      if (match != null) {
        final keywordsText = match.group(1)?.trim();
        if (keywordsText != null) {
          final keywords = keywordsText
              .split(',')
              .map((keyword) => keyword.trim())
              .where((keyword) => keyword.isNotEmpty)
              .toList();
          print('✅ Found keywords in tag: $keywords');
          return keywords;
        }
      }
      
      // Fallback: Look for keywords in the response using various patterns
      
      // Pattern 1: "keywords that would work well for you: keyword1, keyword2, keyword3"
      final pattern1 = RegExp(r'keywords? that would work well for you:\s*([^.!?]+)', caseSensitive: false);
      final match1 = pattern1.firstMatch(response);
      
      if (match1 != null) {
        final keywordsText = match1.group(1)?.trim();
        if (keywordsText != null) {
          final keywords = keywordsText
              .split(',')
              .map((keyword) => keyword.trim())
              .where((keyword) => keyword.isNotEmpty)
              .toList();
          print('✅ Pattern 1 found keywords: $keywords');
          return keywords;
        }
      }
      
      // Pattern 2: "keywords for your profile: keyword1, keyword2, keyword3"
      final pattern2 = RegExp(r'keywords? for your profile:\s*([^.!?]+)', caseSensitive: false);
      final match2 = pattern2.firstMatch(response);
      
      if (match2 != null) {
        final keywordsText = match2.group(1)?.trim();
        if (keywordsText != null) {
          final keywords = keywordsText
              .split(',')
              .map((keyword) => keyword.trim())
              .where((keyword) => keyword.isNotEmpty)
              .toList();
          print('✅ Pattern 2 found keywords: $keywords');
          return keywords;
        }
      }
      
      // Pattern 3: "here are some keywords: keyword1, keyword2, keyword3"
      final pattern3 = RegExp(r'here are some keywords?:\s*([^.!?]+)', caseSensitive: false);
      final match3 = pattern3.firstMatch(response);
      
      if (match3 != null) {
        final keywordsText = match3.group(1)?.trim();
        if (keywordsText != null) {
          final keywords = keywordsText
              .split(',')
              .map((keyword) => keyword.trim())
              .where((keyword) => keyword.isNotEmpty)
              .toList();
          print('✅ Pattern 3 found keywords: $keywords');
          return keywords;
        }
      }
      
      // Pattern 4: "keywords like keyword1, keyword2, keyword3"
      final pattern4 = RegExp(r'keywords? like\s*([\w\s,\-]+)', caseSensitive: false);
      final match4 = pattern4.firstMatch(response);
      
      if (match4 != null) {
        final keywords = match4.group(1)!
            .split(',')
            .map((keyword) => keyword.trim())
            .where((keyword) => keyword.isNotEmpty)
            .toList();
        print('✅ Pattern 4 found keywords: $keywords');
        return keywords;
      }
      
      // Pattern 5: Look for numbered lists like "1. KiteSurfing 2. Adventure 3. Water sports"
      final numberedPattern = RegExp(r'\d+\.\s*([^\n]+)', caseSensitive: false);
      final numberedMatches = numberedPattern.allMatches(response);
      if (numberedMatches.isNotEmpty) {
        final keywords = <String>[];
        for (final match in numberedMatches) {
          final keywordText = match.group(1)?.trim();
          if (keywordText != null && keywordText.isNotEmpty) {
            // Clean up the keyword (remove any trailing numbers or special characters)
            final cleanKeyword = keywordText
                .replaceAll(RegExp(r'\s*\d+$'), '') // Remove trailing numbers
                .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
                .trim();
            if (cleanKeyword.isNotEmpty) {
              keywords.add(cleanKeyword);
            }
          }
        }
        if (keywords.isNotEmpty) {
          print('✅ Pattern 5 (numbered list) found keywords: $keywords');
          return keywords;
        }
      }
      
      print('❌ No keywords found in response');
      return [];
    } catch (e) {
      print('Error extracting keywords: $e');
      return [];
    }
  }
} 