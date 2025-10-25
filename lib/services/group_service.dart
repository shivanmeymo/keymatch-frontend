import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

class GroupService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Create a new group
  static Future<Map<String, dynamic>> createGroup(
    String name, 
    List<int> memberIds, 
    {String? description}
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name.trim(),
          'memberIds': memberIds,
          'description': description?.trim(),
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create group');
      }
    } catch (e) {
      print('Create group error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get all groups for the current user
  static Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/groups'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((group) {
          if (group is Map<String, dynamic>) {
            return group;
          } else {
            print('Warning: Group data is not Map<String, dynamic>: $group');
            return <String, dynamic>{};
          }
        }).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get groups');
      }
    } catch (e) {
      print('Get groups error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get groups to explore (groups user is NOT a member of)
  static Future<List<Map<String, dynamic>>> getGroupsToExplore() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/groups/explore/discover'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((group) {
          if (group is Map<String, dynamic>) {
            return group;
          } else {
            print('Warning: Group data is not Map<String, dynamic>: $group');
            return <String, dynamic>{};
          }
        }).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get groups to explore');
      }
    } catch (e) {
      print('Get groups to explore error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get a specific group by ID
  static Future<Map<String, dynamic>> getGroup(String groupId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Group not found or access denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get group');
      }
    } catch (e) {
      print('Get group error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get messages for a group
  static Future<List<Map<String, dynamic>>> getGroupMessages(String groupId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/messages'),
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
      } else if (response.statusCode == 404) {
        throw Exception('Group not found or access denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get group messages');
      }
    } catch (e) {
      print('Get group messages error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Send a message to a group
  static Future<Map<String, dynamic>> sendGroupMessage(String groupId, String content) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      if (content.trim().isEmpty) {
        throw Exception('Message content cannot be empty.');
      }

      if (content.length > 1000) {
        throw Exception('Message content cannot exceed 1000 characters.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/messages'),
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
      } else if (response.statusCode == 404) {
        throw Exception('Group not found or access denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to send message');
      }
    } catch (e) {
      print('Send group message error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Add a member to a group
  static Future<Map<String, dynamic>> addGroupMember(String groupId, int userProfileId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userProfileId': userProfileId,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add member');
      }
    } catch (e) {
      print('Add group member error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Remove a member from a group
  static Future<void> removeGroupMember(String groupId, int userProfileId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse('$baseUrl/groups/$groupId/members/$userProfileId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to remove member');
      }
    } catch (e) {
      print('Remove group member error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Request to join a group
  static Future<Map<String, dynamic>> requestToJoinGroup(String groupId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/join-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 409) {
        // Already requested or already a member
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Already requested or member');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to request join');
      }
    } catch (e) {
      print('Request to join group error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get join requests for a group (creator only)
  static Future<List<Map<String, dynamic>>> getJoinRequests(String groupId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/join-requests'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((request) {
          if (request is Map<String, dynamic>) {
            return request;
          } else {
            print('Warning: Request data is not Map<String, dynamic>: $request');
            return <String, dynamic>{};
          }
        }).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Only group creator can view join requests');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get join requests');
      }
    } catch (e) {
      print('Get join requests error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Accept a join request (creator only)
  static Future<Map<String, dynamic>> acceptJoinRequest(String groupId, String requestId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/join-requests/$requestId/accept'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Only group creator can accept join requests');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to accept join request');
      }
    } catch (e) {
      print('Accept join request error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Decline a join request (creator only)
  static Future<Map<String, dynamic>> declineJoinRequest(String groupId, String requestId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/join-requests/$requestId/decline'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Only group creator can decline join requests');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to decline join request');
      }
    } catch (e) {
      print('Decline join request error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get count of pending join requests (for badge)
  static Future<Map<String, dynamic>> getJoinRequestsCount(String groupId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/join-requests-count'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'count': 0};
      }
    } catch (e) {
      print('Get join requests count error: $e');
      return {'count': 0};
    }
  }
}


