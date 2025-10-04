
import 'package:mockito/mockito.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/profile_service.dart';

// Define an interface for AuthService to allow mocking
abstract class MockableAuthService {
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<Map<String, dynamic>> verifyEmail(String token);
  Future<Map<String, dynamic>> resendVerificationEmail(String email);
}

// Implement the mockable interface using the actual AuthService static methods
class RealAuthServiceWrapper implements MockableAuthService {
  @override
  Future<Map<String, dynamic>?> getCurrentUser() => AuthService.getCurrentUser();
  @override
  Future<Map<String, dynamic>> verifyEmail(String token) => AuthService.verifyEmail(token);
  @override
  Future<Map<String, dynamic>> resendVerificationEmail(String email) => AuthService.resendVerificationEmail(email);
}

// Define an interface for ProfileService to allow mocking
abstract class MockableProfileService {
  Future<Map<String, dynamic>?> getCompleteProfile();
}

// Implement the mockable interface using the actual ProfileService static methods
class RealProfileServiceWrapper implements MockableProfileService {
  @override
  Future<Map<String, dynamic>?> getCompleteProfile() => ProfileService.getCompleteProfile();
}

// Create Mock classes using Mockito
class MockAuthService extends Mock implements MockableAuthService {}
class MockProfileService extends Mock implements MockableProfileService {}
