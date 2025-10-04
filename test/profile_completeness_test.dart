import 'package:flutter_test/flutter_test.dart';
import 'package:key_match/services/profile_service.dart';

void main() {
  group('Profile Completeness Tests', () {
    test('should correctly identify complete profiles', () {
      final completeProfile = {
        'gender': 'M',
        'genderPreference': 'F',
        'relationshipType': 'C,S',
        'images': [
          {'id': '1', 'imageUrl': 'test.jpg'}
        ],
        'bio': 'Test bio' // Optional
      };
      
      expect(ProfileService.isProfileComplete(completeProfile), isTrue);
    });
    
    test('should correctly identify incomplete profiles', () {
      final incompleteProfile = {
        'gender': 'M',
        'genderPreference': 'F',
        'relationshipType': 'C,S',
        'images': [] // No images
      };
      
      expect(ProfileService.isProfileComplete(incompleteProfile), isFalse);
    });
    
    test('should handle null profile', () {
      // isProfileComplete doesn't accept null, so we test with an empty map
      final emptyProfile = <String, dynamic>{};
      expect(ProfileService.isProfileComplete(emptyProfile), isFalse);
    });
    
    test('should handle profile with missing required fields', () {
      final incompleteProfile = {
        'gender': 'M',
        'genderPreference': 'F',
        // Missing relationshipType and images
      };
      
      expect(ProfileService.isProfileComplete(incompleteProfile), isFalse);
    });
    
    test('should handle profile with empty required fields', () {
      final incompleteProfile = {
        'gender': '',
        'genderPreference': 'F',
        'relationshipType': 'C,S',
        'images': [
          {'id': '1', 'imageUrl': 'test.jpg'}
        ]
      };
      
      expect(ProfileService.isProfileComplete(incompleteProfile), isFalse);
    });
  });
} 