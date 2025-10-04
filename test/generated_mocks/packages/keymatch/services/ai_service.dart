import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class KeyMakerService {
  static String get baseUrl => 'https://key-match-dating-app-a069d14fdf4a.herokuapp.com';

  /// Send a message to the key maker and get a response
  static Future<String> sendMessage(String message, {List<Map<String, dynamic>>? history}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      print('🤖 Sending AI message: $message');
      if (history != null) {
        print('🤖 Message history length: ${history.length}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message,
          'history': history ?? [],
        }),
      );

      print('🤖 AI response status: ${response.statusCode}');
      print('🤖 AI response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['response'] ?? 'Sorry, I couldn\'t process your message.';
        print('🤖 AI response text: $aiResponse');
        return aiResponse;
      } else {
        final errorData = json.decode(response.body);
        print('❌ AI API error: $errorData');
        throw Exception(errorData['error'] ?? 'Failed to get key maker response');
      }
    } catch (e) {
      print('❌ Key maker service error: $e');
      throw Exception('Failed to get key maker response: $e');
    }
  }

  /// Get conversation history for the current user
  static Future<List<Map<String, dynamic>>> getConversationHistory() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/conversation-history'),
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
        Uri.parse('$baseUrl/api/ai/conversation-history'),
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
} 