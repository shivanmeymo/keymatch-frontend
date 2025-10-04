import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login Debug Tests', () {
    test('should handle verified user login response', () {
      // Simulate the backend response for a verified user
      final loginResponse = {
        'success': true,
        'message': 'Login successful!',
        'user': {
          'id': 24,
          'email': 'klas0holmgren@gmail.com',
          'firstName': 'Klas',
          'lastName': 'Holmgren',
          'fullName': 'Klas Holmgren',
          'emailVerified': true, // This should be true
        },
        'token': 'test-token'
      };
      
      // Extract user data
      final user = loginResponse['user'] as Map<String, dynamic>;
      final isEmailVerified = user['emailVerified'] ?? false;
      
      print('=== DEBUG: Login Response ===');
      print('User data: $user');
      print('Email: ${user['email']}');
      print('Email Verified: $isEmailVerified');
      print('Email Verified Type: ${isEmailVerified.runtimeType}');
      
      // Test the logic that determines if user should go to verification
      final shouldGoToVerification = !isEmailVerified;
      print('Should go to verification: $shouldGoToVerification');
      
      expect(isEmailVerified, isTrue);
      expect(shouldGoToVerification, isFalse);
    });
    
    test('should handle unverified user login response', () {
      // Simulate the backend response for an unverified user
      final loginResponse = {
        'success': true,
        'message': 'Login successful!',
        'user': {
          'id': 25,
          'email': 'test@example.com',
          'firstName': 'Test',
          'lastName': 'User',
          'fullName': 'Test User',
          'emailVerified': false, // This should be false
        },
        'token': 'test-token'
      };
      
      // Extract user data
      final user = loginResponse['user'] as Map<String, dynamic>;
      final isEmailVerified = user['emailVerified'] ?? false;
      
      print('=== DEBUG: Unverified User ===');
      print('User data: $user');
      print('Email: ${user['email']}');
      print('Email Verified: $isEmailVerified');
      
      // Test the logic that determines if user should go to verification
      final shouldGoToVerification = !isEmailVerified;
      print('Should go to verification: $shouldGoToVerification');
      
      expect(isEmailVerified, isFalse);
      expect(shouldGoToVerification, isTrue);
    });
    
    test('should handle missing emailVerified field', () {
      // Simulate the backend response with missing emailVerified field
      final loginResponse = {
        'success': true,
        'message': 'Login successful!',
        'user': {
          'id': 26,
          'email': 'test2@example.com',
          'firstName': 'Test2',
          'lastName': 'User2',
          'fullName': 'Test2 User2',
          // emailVerified field is missing
        },
        'token': 'test-token'
      };
      
      // Extract user data
      final user = loginResponse['user'] as Map<String, dynamic>;
      final isEmailVerified = user['emailVerified'] ?? false;
      
      print('=== DEBUG: Missing EmailVerified Field ===');
      print('User data: $user');
      print('Email: ${user['email']}');
      print('Email Verified: $isEmailVerified');
      print('Has emailVerified field: ${user.containsKey('emailVerified')}');
      
      // Test the logic that determines if user should go to verification
      final shouldGoToVerification = !isEmailVerified;
      print('Should go to verification: $shouldGoToVerification');
      
      expect(isEmailVerified, isFalse); // Should default to false
      expect(shouldGoToVerification, isTrue);
    });
  });
} 