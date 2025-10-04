import 'package:key_match/services/billing_service.dart';

// Mock implementation of BillingService for testing
class MockBillingService {
  static bool _isAvailable = false;
  static bool _isInitialized = false;
  
  static bool get isAvailable => _isAvailable;
  
  // Setup methods for testing
  static void setAvailable(bool available) {
    _isAvailable = available;
  }
  
  static void reset() {
    _isAvailable = false;
    _isInitialized = false;
  }
  
  static Future<bool> initialize() async {
    _isInitialized = true;
    return _isAvailable;
  }
  
  static Future<bool> hasActiveSubscription() async {
    return false;
  }
  
  static Future<bool> restorePurchases() async {
    return true;
  }
  
  static Future<bool> purchaseProduct(String productId) async {
    return false;
  }
  
  static List<dynamic> getProducts() {
    return [];
  }
  
  static List<Map<String, dynamic>> getPremiumPlans() {
    return [
      {
        'id': 'test_monthly',
        'name': 'Test Monthly Premium',
        'price': 9.99,
        'period': 'month',
        'duration_days': 30,
      },
      {
        'id': 'test_yearly',
        'name': 'Test Yearly Premium',
        'price': 99.99,
        'period': 'year',
        'duration_days': 365,
      },
    ];
  }
}

// Override the real BillingService with mock for testing
class BillingServiceMock {
  static void setupMock() {
    // This would require dependency injection or a way to override static methods
    // For now, we'll use the mock directly in tests
  }
} 