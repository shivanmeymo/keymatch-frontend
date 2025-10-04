import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'location_service.dart';

class ProfileService {
  // Use the same base URL as AuthService
  static String get baseUrl => 'https://key-match-dating-app-a069d14fdf4a.herokuapp.com';

  // Helper method to construct full image URLs
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // If it's a relative path, construct full URL
    if (imagePath.startsWith('/')) {
      return '$baseUrl$imagePath';
    }
    
    // If it's just a filename, add the uploads path
    return '$baseUrl/uploads/$imagePath';
  }

  static Future<Map<String, dynamic>> createProfile({
    required String bio,
    String? birthDate,
    required String gender,
    required String genderPreference,
    String? location,
    required String relationshipType,
    List<String>? keyWords,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/api/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bio': bio,
          'birthDate': birthDate,
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
    required String bio,
    String? birthDate,
    required String gender,
    required String genderPreference,
    String? location,
    required List<String> relationshipType,
    List<String>? keyWords,
    String? locationMode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Debug logging
      print('=== DEBUG: ProfileService.updateProfile ===');
      print('Bio: $bio');
      print('Gender: $gender');
      print('GenderPreference: $genderPreference');
      print('RelationshipType: $relationshipType');
      print('KeyWords: $keyWords');
      print('Location: $location');
      print('Latitude: $latitude');
      print('Longitude: $longitude');

      // Create HTTP client with timeout
      final client = http.Client();
      
      try {
        final response = await client.put(
          Uri.parse('$baseUrl/api/profiles/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'bio': bio,
            'birthDate': birthDate,
            'gender': gender,
            'genderPreference': genderPreference,
            if (location != null) 'location': location,
            'relationshipType': relationshipType,
            if (keyWords != null) 'keyWords': keyWords,
            if (locationMode != null) 'locationMode': locationMode,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        ).timeout(
          const Duration(seconds: 30), // 30 second timeout
          onTimeout: () {
            throw Exception('Request timeout - server took too long to respond');
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

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
          print('Server error: $errorMessage');
          throw Exception(errorMessage);
        }
      } finally {
        client.close(); // Always close the client
      }
    } catch (e) {
      print('ProfileService.updateProfile error: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('timeout')) {
        throw Exception('Network timeout - please check your connection and try again');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network connection failed - please check your internet connection');
      } else if (e.toString().contains('HandshakeException')) {
        throw Exception('Secure connection failed - please try again');
      } else {
        throw Exception('Network error: $e');
      }
    }
  }

  static Future<void> updateLocationWithGPSCoordinates() async {
    try {
      final coordinates = await LocationService.getLocationCoordinates();
      if (coordinates != null) {
        await updateLocationWithGPS(
          coordinates['latitude']!,
          coordinates['longitude']!,
        );
      }
    } catch (e) {
      print('Error updating location with GPS: $e');
      rethrow;
    }
  }

  static Future<void> updateLocationWithGPS(double latitude, double longitude) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/api/profiles/location/gps'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location: ${response.body}');
      }

      print('Location updated successfully with GPS coordinates');
    } catch (e) {
      print('Error updating location with GPS: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await AuthService.getToken();
      print('=== DEBUG: ProfileService.getProfile ===');
      print('Token: $token');
      
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/profiles/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
        throw Exception(errorData['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      print('ProfileService.getProfile error: $e');
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
          
          print('Web upload - MIME type: $mimeType, File size: ${bytes.length} bytes');
        } catch (e) {
          throw Exception('Failed to read image data from blob URL: $e');
        }
      } else {
        // For mobile, use File
        final file = File(imagePath);
        bytes = await file.readAsBytes();
        fileName = imagePath.split('/').last;
        mimeType = 'image/jpeg'; // Default for mobile
        print('Mobile upload - MIME type: $mimeType, File size: ${bytes.length} bytes');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/profiles/upload-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      
      print('Creating multipart request with MIME type: $mimeType');
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      print('Sending request to: $baseUrl/api/profiles/upload-picture');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
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
      print('🔍 ProfileService.deleteImage called with ID: $imageId');
      
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final url = '$baseUrl/api/profiles/images/$imageId';
      print('🔍 Making DELETE request to: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete image');
      }
      
      print('✅ Image deletion successful in ProfileService');
    } catch (e) {
      print('❌ ProfileService.deleteImage error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getPotentialMatches({String? genderPreference}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Construct URI with genderPreference if provided
      final Uri uri = Uri.parse('$baseUrl/api/profiles/potential-matches').replace(queryParameters: {
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
        print('🔍 API Response data type: ${data.runtimeType}');
        print('🔍 API Response keys: ${data.keys.toList()}');
        
        final List<dynamic> profilesData = data['profiles'] ?? [];
        print('🔍 Profiles data type: ${profilesData.runtimeType}');
        print('🔍 Profiles data length: ${profilesData.length}');
        if (profilesData.isNotEmpty) {
          print('🔍 First profile type: ${profilesData.first.runtimeType}');
          print('🔍 First profile: ${profilesData.first}');
        }
        
        // Safely convert List<dynamic> to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> matches = profilesData.map((profile) {
          if (profile is Map<String, dynamic>) {
            return profile;
          } else {
            // If the profile is not the expected type, create an empty map
            print('⚠️ Warning: Profile data is not Map<String, dynamic>: $profile');
            print('⚠️ Profile type: ${profile.runtimeType}');
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
        
        // Return both profiles and suggestion if present
        return {
          'profiles': matches,
          if (data['suggestion'] != null) 'suggestion': data['suggestion'],
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get potential matches');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> likeProfile(String profileId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      print('Sending like request with profileId: $profileId');
      final requestData = {
        'profileId': profileId,
      };
      print('Request data: $requestData');

      final response = await http.post(
        Uri.parse('$baseUrl/api/matches/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      print('Like response status: ${response.statusCode}');
      print('Like response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to like profile');
      }
    } catch (e) {
      print('Like profile error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> dislikeProfile(String profileId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/matches/dislike'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'profileId': profileId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to dislike profile');
      }
    } catch (e) {
      print('Dislike profile error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfileById(String profileId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/profiles/$profileId'),
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
        Uri.parse('$baseUrl/api/profiles/me'),
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
      print('Error getting location mode: $e');
      return null;
    }
  }

  /// Update location mode in backend
  static Future<void> updateLocationMode(String mode) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/api/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'locationMode': mode,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update location mode');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if a profile is complete (has all required fields)
  static bool isProfileComplete(Map<String, dynamic> profile) {
    // Check if profile has required fields
    final hasBio = profile['bio'] != null && profile['bio'].toString().trim().isNotEmpty;
    final hasGender = profile['gender'] != null && profile['gender'].toString().isNotEmpty;
    final hasGenderPreference = profile['genderPreference'] != null && profile['genderPreference'].toString().isNotEmpty;
    final hasRelationshipType = profile['relationshipType'] != null;
    final hasImages = profile['images'] != null && profile['images'] is List && profile['images'].isNotEmpty;
    
    // Profile is complete if it has all required fields
    return hasBio && hasGender && hasGenderPreference && hasRelationshipType && hasImages;
  }

  /// Get profile and check if it's complete
  static Future<Map<String, dynamic>?> getCompleteProfile() async {
    try {
      final profile = await getProfile();
      if (isProfileComplete(profile)) {
        return profile;
      } else {
        // Profile exists but is incomplete
        throw Exception('Profile incomplete');
      }
    } catch (e) {
      // Profile doesn't exist or is incomplete
      return null;
    }
  }
} 