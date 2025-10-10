import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'location_service.dart';
import '../constants/api_config.dart';

class ProfileService {
  // Use the centralized API configuration with /api already included
  static String get baseUrl => ApiConfig.apiBaseUrl;

  // Helper method to construct full image URLs
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return as is (including Google Cloud Storage URLs)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // If it's a relative path starting with /uploads/, construct full URL
    if (imagePath.startsWith('/uploads/')) {
      return '${ApiConfig.baseUrl}$imagePath';
    }
    
    // If it's just a filename, add the uploads path
    if (!imagePath.contains('/')) {
      return '${ApiConfig.baseUrl}/uploads/$imagePath';
    }
    
    // For any other relative paths, return as is (let the backend handle it)
    return imagePath;
  }

  static Future<Map<String, dynamic>> createProfile({
    String? bio,
    String? birthDate,
    required String gender,
    required String genderPreference,
    String? location,
    required String relationshipType,
    List<String>? keyWords,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'PUT',
        '/profiles/me',
        body: json.encode({
          if (bio != null) 'bio': bio,
          if (birthDate != null) 'birthDate': birthDate,
          'gender': gender,
          'genderPreference': genderPreference,
          if (location != null) 'location': location,
          'relationshipType': relationshipType,
          if (keyWords != null) 'keyWords': keyWords,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Transform image URLs to full URLs
        if (data['profilePicture'] != null) {
          data['profilePicture'] = getFullImageUrl(data['profilePicture']);
        }
        if (data['images'] != null && data['images'] is List) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? bio,
    String? birthDate,
    String? gender,
    required String genderPreference,
    String? location,
    required List<String> relationshipType,
    List<String>? keyWords,
    String? locationMode,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Create HTTP client with timeout
      final client = http.Client();
      
      // Create the request body
      final requestBody = {
        if (bio != null) 'bio': bio,
        if (birthDate != null) 'birthDate': birthDate,
        if (gender != null) 'gender': gender,
        'genderPreference': genderPreference,
        if (location != null) 'location': location,
        'relationshipType': relationshipType,
        if (keyWords != null) 'keyWords': keyWords,
        if (locationMode != null) 'locationMode': locationMode,
        if (images != null) 'images': images, // Include images if provided
      };
      
      final jsonBody = json.encode(requestBody);
      
      try {
        final response = await client.put(
          Uri.parse('$baseUrl/profiles/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonBody,
        ).timeout(
          const Duration(seconds: 30), // 30 second timeout
          onTimeout: () {
            throw Exception('Request timeout - server took too long to respond');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Transform image URLs to full URLs
          if (data['profilePicture'] != null) {
            data['profilePicture'] = getFullImageUrl(data['profilePicture']);
          }
          if (data['images'] != null && data['images'] is List) {
            for (var image in data['images']) {
              if (image['imageUrl'] != null) {
                image['imageUrl'] = getFullImageUrl(image['imageUrl']);
              }
            }
          }
          return data;
        } else {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error'] ?? 'Failed to update profile';
          throw Exception(errorMessage);
        }
      } finally {
        client.close(); // Always close the client
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> updateImageOrder(List<Map<String, dynamic>> images) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/images/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({ 'imageOrders': images }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update image order');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/profiles/me',
      ).timeout(
        const Duration(seconds: 15), // 15 second timeout
        onTimeout: () {
          throw Exception('Profile request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Transform image URLs to full URLs
        if (data['profilePicture'] != null) {
          data['profilePicture'] = getFullImageUrl(data['profilePicture']);
        }
        if (data['images'] != null && data['images'] is List) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }
        return data;
      } else if (response.statusCode == 404) {
        // Profile not found - this is expected for new users
        throw Exception('Profile not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      Uint8List bytes;
      String fileName;
      String mimeType;

      if (kIsWeb) {
        // For web, handle blob URL
        try {
          final response = await http.get(Uri.parse(imagePath));
          bytes = response.bodyBytes;
          fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          // Try to determine MIME type from response headers
          mimeType = response.headers['content-type'] ?? 'image/jpeg';
          
          // If no content-type header, try to determine from the blob URL or default to jpeg
          if (mimeType.isEmpty || mimeType == 'text/plain') {
            mimeType = 'image/jpeg';
          }
        } catch (e) {
          throw Exception('Failed to read image data from blob URL: $e');
        }
      } else {
        // For mobile, use File
        final file = File(imagePath);
        bytes = await file.readAsBytes();
        fileName = imagePath.split('/').last;
        mimeType = 'image/jpeg'; // Default for mobile
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profiles/upload-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Transform image URLs to full URLs
        if (data['images'] != null && data['images'] is List && data['images'].isNotEmpty) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }
        
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to upload profile picture');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> deleteImage(String imageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final url = '$baseUrl/profiles/images/$imageId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete image');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getPotentialMatches({String? genderPreference}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Construct URI with genderPreference if provided
      final Uri uri = Uri.parse('$baseUrl/profiles/potential-matches').replace(queryParameters: {
        if (genderPreference != null) 'genderPreference': genderPreference,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        final List<dynamic> profilesData = data['profiles'] ?? [];
        
        // Safely convert List<dynamic> to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> matches = profilesData.map((profile) {
          if (profile is Map<String, dynamic>) {
            return profile;
          } else {
            // If the profile is not the expected type, create an empty map
            return <String, dynamic>{};
          }
        }).toList();
        
        // Transform image URLs to full URLs for all matches
        for (var match in matches) {
          if (match['profilePicture'] != null) {
            match['profilePicture'] = getFullImageUrl(match['profilePicture']);
          }
          if (match['images'] != null && match['images'] is List) {
            for (var image in match['images']) {
              if (image['imageUrl'] != null) {
                image['imageUrl'] = getFullImageUrl(image['imageUrl']);
              }
            }
          }
        }
        
        return { 'profiles': matches };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get potential matches');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> likeProfile(String profileId, {String? message}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final requestData = {
        'profileId': profileId,
        if (message != null) 'message': message,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/profiles/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to like profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> likeProfileWithMessage(String profileId, String message) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final requestData = {
        'profileId': profileId,
        'message': message,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/profiles/like-with-message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to like profile with message');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> dislikeProfile(String profileId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/profiles/dislike'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({ 'profileId': profileId }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to dislike profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfileById(String profileId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/$profileId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Transform image URLs to full URLs
        if (data['profilePicture'] != null) {
          data['profilePicture'] = getFullImageUrl(data['profilePicture']);
        }
        if (data['images'] != null && data['images'] is List) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get profile by id');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get location mode from backend
  static Future<String?> getLocationMode() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['locationMode'] as String?;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get location mode');
      }
    } catch (e) {
      return null;
    }
  }

  /// Update location mode in backend
  static Future<void> updateLocationMode(String locationMode) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({ 'locationMode': locationMode }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update location mode');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if profile is complete (has all required fields)
  static bool isProfileComplete(Map<String, dynamic> profile) {
    return profile['gender'] != null &&
           profile['genderPreference'] != null &&
           profile['relationshipType'] != null &&
           profile['images'] != null &&
           profile['images'] is List &&
           profile['images'].isNotEmpty;
  }

  /// Get complete profile (profile that has finished initial setup)
  static Future<Map<String, dynamic>?> getCompleteProfile() async {
    try {
      final profile = await getProfile().timeout(
        const Duration(seconds: 15), // 15 second timeout
        onTimeout: () {
          throw Exception('Profile request timeout');
        },
      );
      
      if (isProfileComplete(profile)) {
        return profile;
      } else {
        // Profile exists but is incomplete
        throw Exception('Profile incomplete: Missing required fields');
      }
    } catch (e) {
      // Check if this is a network or authentication error
      if (e.toString().contains('Network error') || 
          e.toString().contains('No authentication token') ||
          e.toString().contains('401') ||
          e.toString().contains('403') ||
          e.toString().contains('timeout')) {
        rethrow;
      }
      
      // Check if this is a "Profile not found" error
      if (e.toString().contains('Profile not found')) {
        return null;
      }
      
      // For other errors (like profile incomplete), return null
      return null;
    }
  }

  /// Hide account - profile will not appear in AI chat or Explore Area
  static Future<Map<String, dynamic>> hideAccount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/profiles/hide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to hide account');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Unhide account - profile will appear in AI chat and Explore Area again
  static Future<Map<String, dynamic>> unhideAccount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/profiles/unhide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to unhide account');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get account visibility status
  static Future<bool> getAccountVisibility() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/visibility'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isHidden'] ?? false;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get account visibility');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}