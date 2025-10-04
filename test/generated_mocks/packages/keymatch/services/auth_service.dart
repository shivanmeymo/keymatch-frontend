import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';  // Re-enabled for token storage
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'session_manager.dart';

class AuthService {
  static const String baseUrl = 'https://key-match-dating-app-a069d14fdf4a.herokuapp.com/api';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Helper method to handle API errors
  static String _handleApiError(dynamic response) {
    try {
      if (response is http.Response) {
        final body = json.decode(response.body);
        
        // Handle structured error responses
        if (body['error'] != null) {
          return body['error'];
        }
        
        if (body['message'] != null) {
          return body['message'];
        }
        
        // Handle different HTTP status codes
        switch (response.statusCode) {
          case 400:
            return 'Invalid request. Please check your input and try again.';
          case 401:
            return 'Authentication failed. Please check your credentials.';
          case 403:
            return 'Access denied. You don\'t have permission to perform this action.';
          case 404:
            return 'The requested resource was not found.';
          case 429:
            return 'Too many requests. Please wait a moment and try again.';
          case 500:
            return 'Server error. Please try again later.';
          case 503:
            return 'Service temporarily unavailable. Please try again in a few moments.';
          default:
            return 'An unexpected error occurred. Please try again.';
        }
      }
    } catch (e) {
      print('Error parsing API response: $e');
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  // Helper method to get user-friendly error messages
  static String _getUserFriendlyError(String errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'MISSING_CREDENTIALS':
        return 'Please provide both email and password.';
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'EMAIL_ALREADY_EXISTS':
        return 'An account with this email already exists. Please try logging in instead.';
      case 'USER_NOT_FOUND':
        return 'No account found with this email address. Please check your email or register a new account.';
      case 'EMAIL_ALREADY_VERIFIED':
        return 'This email is already verified. You can log in to your account.';
      case 'INVALID_TOKEN':
        return 'Invalid or expired verification token. Please request a new verification email.';
      case 'EXPIRED_TOKEN':
        return 'Verification token has expired. Please request a new verification email.';
      case 'MISSING_TOKEN':
        return 'Verification token is required.';
      case 'MISSING_EMAIL':
        return 'Email address is required.';
      case 'VALIDATION_ERROR':
        return 'Please check your input and try again.';
      case 'DATABASE_CONNECTION_ERROR':
        return 'Database connection failed. Please try again in a few moments.';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many requests. Please wait a moment and try again.';
      case 'SIGNUP_FAILED':
        return 'Registration failed. Please try again.';
      case 'SIGNIN_FAILED':
        return 'Login failed. Please check your credentials and try again.';
      case 'SIGNUP_DISABLED':
        return 'Registration is currently disabled. Please try again later.';
      case 'SIGNIN_DISABLED':
        return 'Login is currently disabled. Please try again later.';
      case 'EMAIL_VERIFICATION_FAILED':
        return 'Email verification failed. Please check your email and try again.';
      case 'INTERNAL_SERVER_ERROR':
        return 'An unexpected error occurred. Please try again.';
      default:
        return defaultMessage;
    }
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Registration successful!',
          'user': body['user'],
          'emailSent': body['emailSent'] ?? false,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, body['token']);
        await prefs.setString(userKey, json.encode(body['user']));

        return {
          'success': true,
          'message': 'Login successful!',
          'user': body['user'],
          'token': body['token'],
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Verify email
  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update user data in SharedPreferences to reflect emailVerified status
        final prefs = await SharedPreferences.getInstance();
        final updatedUser = body['user'];
        await prefs.setString(userKey, json.encode(updatedUser));

        return {
          'success': true,
          'message': body['message'] ?? 'Email verified successfully!',
          'user': updatedUser,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Resend verification email
  static Future<Map<String, dynamic>> resendVerification({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Verification email sent successfully!',
          'emailSent': body['emailSent'] ?? false,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': true,
          'message': 'Already logged out.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Clear local storage regardless of response
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Successfully logged out.',
        };
      } else {
        return {
          'success': true,
          'message': 'Logged out locally.',
        };
      }
    } catch (e) {
      // Clear local storage even if network request fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);
      
      return {
        'success': true,
        'message': 'Logged out locally.',
      };
    }
  }

  // Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body;
      } else {
        // Token might be invalid, clear it
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(tokenKey);
        await prefs.remove(userKey);
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Check if user email is verified
  static Future<bool> isEmailVerified() async {
    final userData = await getUserData();
    return userData?['emailVerified'] == true;
  }

  /// Initialize authentication system
  static Future<bool> initialize() async {
    try {
      print('=== DEBUG: AuthService.initialize ===');
      
      // Initialize session manager
      final hasValidSession = await SessionManager.initializeSession();
      
      if (hasValidSession) {
        print('Valid session found and restored');
        return true;
      } else {
        print('No valid session found');
        return false;
      }
    } catch (e) {
      print('AuthService initialization error: $e');
      return false;
    }
  }

  /// Refresh session if needed
  static Future<bool> refreshSessionIfNeeded() async {
    try {
      return await SessionManager.refreshSession();
    } catch (e) {
      print('Refresh session error: $e');
      return false;
    }
  }

  /// Get session statistics for debugging
  static Future<Map<String, dynamic>> getSessionStats() async {
    try {
      return await SessionManager.getSessionStats();
    } catch (e) {
      print('Get session stats error: $e');
      return {'error': e.toString()};
    }
  }

  // Sign in method (alias for login)
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    return await login(email: email, password: password);
  }

  // Sign up method (alias for register)
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  // Sign out method (alias for logout)
  static Future<void> signOut() async {
    await logout();
  }

  // Resend verification email method (alias for resendVerification)
  static Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    return await resendVerification(email: email);
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await isLoggedIn();
  }

  // Update user profile picture
  static Future<void> updateUserProfilePicture(String imageUrl) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/picture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'imageUrl': imageUrl}),
      );

      if (response.statusCode != 200) {
        final body = json.decode(response.body);
        throw Exception(body['error'] ?? 'Failed to update profile picture');
      }
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }
} 