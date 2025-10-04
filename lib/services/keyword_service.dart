import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

class KeywordService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Get keyword suggestions based on query
  static Future<List<String>> getSuggestions(String query) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/keywords/suggestions').replace(queryParameters: {
          'query': query,
          'limit': '10',
        }),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List;
        return suggestions.map((suggestion) => suggestion['keyword'] as String).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get keyword suggestions');
      }
    } catch (e) {
      print('Get keyword suggestions error: $e');
      return [];
    }
  }

  /// Get popular keywords by category
  static Future<List<Map<String, dynamic>>> getPopularKeywords({String? category}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final queryParams = <String, String>{
        'limit': '20',
      };
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/keywords/popular').replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final keywords = data['keywords'] as List;
        return keywords.map((keyword) => keyword as Map<String, dynamic>).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get popular keywords');
      }
    } catch (e) {
      print('Get popular keywords error: $e');
      return [];
    }
  }

  /// Get keyword categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/keywords/categories'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories = data['categories'] as List;
        return categories.map((category) => category as Map<String, dynamic>).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get keyword categories');
      }
    } catch (e) {
      print('Get keyword categories error: $e');
      return [];
    }
  }

  /// Track keyword usage when user adds keywords to profile
  static Future<bool> trackKeywordUsage(List<String> keywords) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/keywords/track-usage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'keywords': keywords,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Keyword usage tracked successfully');
        return true;
      } else {
        final errorData = json.decode(response.body);
        print('❌ Failed to track keyword usage: ${errorData['error']}');
        return false;
      }
    } catch (e) {
      print('Track keyword usage error: $e');
      return false;
    }
  }

  /// Get keyword analytics for user
  static Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/keywords/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get keyword analytics');
      }
    } catch (e) {
      print('Get keyword analytics error: $e');
      return null;
    }
  }

  /// Parse keywords from comma-separated string
  static List<String> parseKeywords(String keywordString) {
    if (keywordString.trim().isEmpty) return [];
    
    return keywordString
        .split(',')
        .map((keyword) => keyword.trim())
        .where((keyword) => keyword.isNotEmpty)
        .toList();
  }

  /// Format keywords to comma-separated string
  static String formatKeywords(List<String> keywords) {
    return keywords.join(', ');
  }

  /// Validate keyword
  static bool isValidKeyword(String keyword) {
    if (keyword.trim().isEmpty) return false;
    if (keyword.length > 50) return false; // Increased from 100 to 50 for consistency
    
    // Check if keyword contains only allowed characters
    final validPattern = RegExp(r'^[a-zA-Z0-9\s\-_]+$');
    return validPattern.hasMatch(keyword);
  }

  /// Get keyword category suggestions based on keyword content
  static String suggestCategory(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    
    if (lowerKeyword.contains('music') || lowerKeyword.contains('guitar') || 
        lowerKeyword.contains('piano') || lowerKeyword.contains('singing')) {
      return 'hobby';
    }
    
    if (lowerKeyword.contains('fitness') || lowerKeyword.contains('gym') || 
        lowerKeyword.contains('running') || lowerKeyword.contains('workout')) {
      return 'activity';
    }
    
    if (lowerKeyword.contains('travel') || lowerKeyword.contains('adventure') || 
        lowerKeyword.contains('explore')) {
      return 'lifestyle';
    }
    
    if (lowerKeyword.contains('creative') || lowerKeyword.contains('artistic') || 
        lowerKeyword.contains('imaginative')) {
      return 'personality';
    }
    
    if (lowerKeyword.contains('technology') || lowerKeyword.contains('science') || 
        lowerKeyword.contains('business')) {
      return 'interest';
    }
    
    return 'other';
  }
} 