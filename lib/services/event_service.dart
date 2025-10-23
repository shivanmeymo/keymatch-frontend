import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

class EventService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  // Create a new event
  static Future<Map<String, dynamic>> createEvent({
    required String name,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? eventDate,
    String? eventTime,
    int? maxParticipants,
    List<String>? tags,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
          'eventDate': eventDate?.toIso8601String(),
          'eventTime': eventTime,
          'maxParticipants': maxParticipants,
          'tags': tags ?? [],
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Event created successfully',
          'event': body['event'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to create event',
          'code': body['code'],
        };
      }
    } catch (e) {
      print('Error creating event: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Get all events
  static Future<Map<String, dynamic>> getEvents({
    int page = 1,
    int limit = 20,
    String status = 'upcoming',
    String sortBy = 'distance',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/events?page=$page&limit=$limit&status=$status&sortBy=$sortBy'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return {
          'success': true,
          'events': body['events'] ?? [],
          'totalCount': body['totalCount'] ?? 0,
          'currentPage': body['currentPage'] ?? 1,
          'totalPages': body['totalPages'] ?? 1,
        };
      } else {
        final body = json.decode(response.body);
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to get events',
          'events': [],
        };
      }
    } catch (e) {
      print('Error getting events: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'events': [],
      };
    }
  }

  // Get single event by ID
  static Future<Map<String, dynamic>> getEventById(String eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return {
          'success': true,
          'event': body['event'],
        };
      } else {
        final body = json.decode(response.body);
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to get event',
        };
      }
    } catch (e) {
      print('Error getting event: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update event
  static Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    String? name,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? eventDate,
    String? eventTime,
    int? maxParticipants,
    String? status,
    List<String>? tags,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (location != null) 'location': location,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (eventDate != null) 'eventDate': eventDate.toIso8601String(),
          if (eventTime != null) 'eventTime': eventTime,
          if (maxParticipants != null) 'maxParticipants': maxParticipants,
          if (status != null) 'status': status,
          if (tags != null) 'tags': tags,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Event updated successfully',
          'event': body['event'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to update event',
        };
      }
    } catch (e) {
      print('Error updating event: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete event
  static Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Event deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to delete event',
        };
      }
    } catch (e) {
      print('Error deleting event: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Participate in event
  static Future<Map<String, dynamic>> participateInEvent({
    required String eventId,
    required String status, // 'interested', 'going', 'not_going', 'maybe'
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/participate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Participation updated',
          'participation': body['participation'],
          'event': body['event'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to participate',
        };
      }
    } catch (e) {
      print('Error participating in event: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Leave event
  static Future<Map<String, dynamic>> leaveEvent(String eventId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId/participate'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Left event successfully',
          'event': body['event'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to leave event',
        };
      }
    } catch (e) {
      print('Error leaving event: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get my created events
  static Future<Map<String, dynamic>> getMyEvents() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/events/my-events'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return {
          'success': true,
          'events': body['events'] ?? [],
        };
      } else {
        final body = json.decode(response.body);
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to get your events',
          'events': [],
        };
      }
    } catch (e) {
      print('Error getting my events: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'events': [],
      };
    }
  }

  // Get my participations
  static Future<Map<String, dynamic>> getMyParticipations() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/events/my-participations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return {
          'success': true,
          'participations': body['participations'] ?? [],
        };
      } else {
        final body = json.decode(response.body);
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to get your participations',
          'participations': [],
        };
      }
    } catch (e) {
      print('Error getting participations: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'participations': [],
      };
    }
  }
}

