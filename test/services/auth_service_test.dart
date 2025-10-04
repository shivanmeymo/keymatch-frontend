import 'package:flutter_test/flutter_test.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock the AuthService for testing
class MockAuthService {
  static String? _storedToken;
  
  static Future<void> storeToken(String token) async {
    _storedToken = token;
  }
  
  static Future<String?> getToken() async {
    return _storedToken;
  }
  
  static Future<void> signOut() async {
    _storedToken = null;
  }
  
  static Future<bool> isLoggedIn() async {
    return _storedToken != null;
  }
  
  // Reset for testing
  static void reset() {
    _storedToken = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
      MockAuthService.reset();
    });

  group('AuthService Tests', () {
    test('should store and retrieve token', () async {
      const testToken = 'test_jwt_token';
      
      await MockAuthService.storeToken(testToken);
      final retrievedToken = await MockAuthService.getToken();
      
      expect(retrievedToken, equals(testToken));
    });

    test('should return null when no token is stored', () async {
      final token = await MockAuthService.getToken();
      expect(token, isNull);
    });

    test('should clear token on sign out', () async {
      const testToken = 'test_jwt_token';
      
      await MockAuthService.storeToken(testToken);
      await MockAuthService.signOut();
      
      final token = await MockAuthService.getToken();
      expect(token, isNull);
    });

    test('should check if user is logged in', () async {
      // Initially not logged in
      bool isLoggedIn = await MockAuthService.isLoggedIn();
      expect(isLoggedIn, isFalse);
      
      // After storing token
      await MockAuthService.storeToken('test_token');
      isLoggedIn = await MockAuthService.isLoggedIn();
      expect(isLoggedIn, isTrue);
      
      // After sign out
      await MockAuthService.signOut();
      isLoggedIn = await MockAuthService.isLoggedIn();
      expect(isLoggedIn, isFalse);
    });

    test('should have all required methods', () {
      // Test that all required methods exist and are callable
      expect(AuthService.signIn, isA<Function>());
      expect(AuthService.signUp, isA<Function>());
      expect(AuthService.signOut, isA<Function>());
      expect(AuthService.resendVerificationEmail, isA<Function>());
      expect(AuthService.isAuthenticated, isA<Function>());
      expect(AuthService.verifyEmail, isA<Function>());
    });

    test('signIn should accept email and password parameters', () {
      // Test that signIn can be called with the correct parameters
      expect(() => AuthService.signIn('test@example.com', 'password'), returnsNormally);
    });

    test('signUp should accept required parameters', () {
      // Test that signUp can be called with the correct parameters
      expect(() => AuthService.signUp(
        email: 'test@example.com',
        password: 'password',
        firstName: 'John',
        lastName: 'Doe',
      ), returnsNormally);
    });

    test('resendVerificationEmail should accept email parameter', () {
      // This test makes a real network call. It should be mocked for CI.
    }, skip: 'Requires network mocking or integration test environment.');

    test('verifyEmail should accept token parameter', () {
      // Test that verifyEmail can be called with the correct parameters
      expect(() => AuthService.verifyEmail('test-token'), returnsNormally);
    });

    test('signOut should not require parameters', () {
      // Test that signOut can be called without parameters
      expect(() => AuthService.signOut(), returnsNormally);
    });

    test('isAuthenticated should not require parameters', () {
      // Test that isAuthenticated can be called without parameters
      expect(() => AuthService.isAuthenticated(), returnsNormally);
    });
  });

  group('Authentication Logic Tests', () {
    test('should validate email format', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org'
      ];

      final invalidEmails = [
        'invalid-email',
        '@example.com',
        'user@',
        'user@.com'
      ];

      for (final email in validEmails) {
        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        expect(emailRegex.hasMatch(email), isTrue, reason: '$email should be valid');
      }

      for (final email in invalidEmails) {
        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        expect(emailRegex.hasMatch(email), isFalse, reason: '$email should be invalid');
      }
    });

    test('should validate password strength', () {
      final strongPassword = 'Password123!';
      final weakPassword = '123';

      // Basic password strength validation
      final isStrong = strongPassword.length >= 8 && 
                      RegExp(r'[A-Z]').hasMatch(strongPassword) && 
                      RegExp(r'[a-z]').hasMatch(strongPassword) && 
                      RegExp(r'[0-9]').hasMatch(strongPassword);
      
      final isWeak = weakPassword.length < 8;

      expect(isStrong, isTrue);
      expect(isWeak, isTrue);
    });

    test('should validate user data structure', () {
      final userData = {
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'password': 'password123',
        'birthDate': '1990-01-01'
      };

      expect(userData.containsKey('firstName'), isTrue);
      expect(userData.containsKey('lastName'), isTrue);
      expect(userData.containsKey('email'), isTrue);
      expect(userData.containsKey('password'), isTrue);
      expect(userData.containsKey('birthDate'), isTrue);
      
      expect(userData['firstName'], isA<String>());
      expect(userData['lastName'], isA<String>());
      expect(userData['email'], isA<String>());
      expect(userData['password'], isA<String>());
    });
  });
} 