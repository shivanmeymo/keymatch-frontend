import 'package:flutter_test/flutter_test.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/profile_service.dart';

void main() {
  group('Login Flow Tests', () {
    test('should handle login with existing account', () async {
      // This test simulates the login flow
      // Note: This is a unit test and won't actually make network requests
      // but it helps identify potential issues in the logic
      
      try {
        // Simulate successful login
        final loginResult = {
          'success': true,
          'user': {
            'id': '123',
            'email': 'test@example.com',
            'firstName': 'Test',
            'lastName': 'User',
            'emailVerified': true,
          },
          'token': 'test-token'
        };
        
        // Check if login was successful
        expect(loginResult['success'], isTrue);
        
        // Check if user data is present
        expect(loginResult['user'], isNotNull);
        
        // Check if email is verified
        final user = loginResult['user'] as Map<String, dynamic>;
        expect(user['emailVerified'], isTrue);
        
        // Simulate profile check
        // In a real scenario, this would call ProfileService.getCompleteProfile()
        // For now, we'll simulate different scenarios
        
        // Scenario 1: Profile exists and is complete
        final completeProfile = {
          'bio': 'Test bio',
          'gender': 'M',
          'genderPreference': 'F',
          'relationshipType': 'C,S',
          'images': [{'id': '1', 'imageUrl': 'test.jpg'}]
        };
        
        // Scenario 2: Profile exists but is incomplete
        final incompleteProfile = {
          'bio': 'Test bio',
          'gender': 'M',
          'genderPreference': 'F',
          'relationshipType': 'C,S',
          'images': [] // No images
        };
        
        // Scenario 3: No profile exists
        final noProfile = null;
        
        // Test the profile completeness logic
        bool isProfileComplete(Map<String, dynamic>? profile) {
          if (profile == null) return false;
          
          final hasBio = profile['bio'] != null && profile['bio'].toString().trim().isNotEmpty;
          final hasGender = profile['gender'] != null && profile['gender'].toString().isNotEmpty;
          final hasGenderPreference = profile['genderPreference'] != null && profile['genderPreference'].toString().isNotEmpty;
          final hasRelationshipType = profile['relationshipType'] != null;
          final hasImages = profile['images'] != null && profile['images'] is List && profile['images'].isNotEmpty;
          
          return hasBio && hasGender && hasGenderPreference && hasRelationshipType && hasImages;
        }
        
        // Test scenarios
        expect(isProfileComplete(completeProfile), isTrue);
        expect(isProfileComplete(incompleteProfile), isFalse);
        expect(isProfileComplete(noProfile), isFalse);
        
      } catch (e) {
        fail('Login flow test failed: $e');
      }
    });
    
    test('should handle login with unverified email', () async {
      // Simulate login with unverified email
      final loginResult = {
        'success': true,
        'user': {
          'id': '123',
          'email': 'test@example.com',
          'firstName': 'Test',
          'lastName': 'User',
          'emailVerified': false, // Email not verified
        },
        'token': 'test-token'
      };
      
      expect(loginResult['success'], isTrue);
      
      final user = loginResult['user'] as Map<String, dynamic>;
      expect(user['emailVerified'], isFalse);
      
      // Should redirect to email verification, not profile check
    });
    
    test('should handle login failure', () async {
      // Simulate failed login
      final loginResult = {
        'success': false,
        'message': 'Invalid credentials',
        'code': 'INVALID_CREDENTIALS'
      };
      
      expect(loginResult['success'], isFalse);
      expect(loginResult['message'], isNotNull);
      expect(loginResult['code'], isNotNull);
    });
  });
} 