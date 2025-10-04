import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../constants/api_config.dart';

// Import for Android-specific product details
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

class BillingService {
  static String get _baseUrl => ApiConfig.apiBaseUrl;
  
  // Product IDs for Google Play Console (Android)
  static const String _monthlyPremiumIdAndroid = 'keymatch_monthly_premium';
  static const String _yearlyPremiumIdAndroid = 'keymatch_yearly_premium';
  static const String _boostPackIdAndroid = 'keymatch_boost_pack';
  static const String _superLikePackIdAndroid = 'keymatch_super_like_pack';
  
  // Product IDs for App Store Connect (iOS)
  static const String _monthlyPremiumIdIOS = 'keymatch_monthly_premium_ios';
  static const String _yearlyPremiumIdIOS = 'keymatch_yearly_premium_ios';
  static const String _boostPackIdIOS = 'keymatch_boost_pack_ios';
  static const String _superLikePackIdIOS = 'keymatch_super_like_pack_ios';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];
  
  // Get platform-specific product IDs
  static Set<String> get _productIds {
    print('🔍 Getting product IDs for platform: $defaultTargetPlatform');
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      print('🔍 Using Android product IDs');
      return {
        _monthlyPremiumIdAndroid,
        _yearlyPremiumIdAndroid,
        _boostPackIdAndroid,
        _superLikePackIdAndroid,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      print('🔍 Using iOS product IDs');
      return {
        _monthlyPremiumIdIOS,
        _yearlyPremiumIdIOS,
        _boostPackIdIOS,
        _superLikePackIdIOS,
      };
    } else {
      print('🔍 Platform not supported: $defaultTargetPlatform, using fallback product IDs');
      // Fallback product IDs for unsupported platforms
      return {
        'fallback_monthly',
        'fallback_yearly',
      };
    }
  }
  
  // Premium plans configuration
  static Map<String, Map<String, dynamic>> get _premiumPlans {
    print('🔍 Getting premium plans for platform: $defaultTargetPlatform');
    print('🔍 Platform type: ${defaultTargetPlatform.runtimeType}');
    print('🔍 Is Android: ${defaultTargetPlatform == TargetPlatform.android}');
    print('🔍 Is iOS: ${defaultTargetPlatform == TargetPlatform.iOS}');
    
    // Always provide fallback plans as a safety net
    final fallbackPlans = {
      'fallback_monthly': {
        'name': 'Monthly Premium',
        'price': 9.99,
        'period': 'month',
        'duration_days': 30,
      },
      'fallback_yearly': {
        'name': 'Yearly Premium',
        'price': 99.99,
        'period': 'year',
        'duration_days': 365,
      },
    };
    
    Map<String, Map<String, dynamic>> result;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      print('🔍 Using Android plans');
      result = {
        _monthlyPremiumIdAndroid: {
          'name': 'Monthly Premium',
          'price': 9.99,
          'period': 'month',
          'duration_days': 30,
        },
        _yearlyPremiumIdAndroid: {
          'name': 'Yearly Premium',
          'price': 99.99,
          'period': 'year',
          'duration_days': 365,
        },
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      print('🔍 Using iOS plans');
      result = {
        _monthlyPremiumIdIOS: {
          'name': 'Monthly Premium',
          'price': 9.99,
          'period': 'month',
          'duration_days': 30,
        },
        _yearlyPremiumIdIOS: {
          'name': 'Yearly Premium',
          'price': 99.99,
          'period': 'year',
          'duration_days': 365,
        },
      };
    } else {
      print('🔍 Platform not supported: $defaultTargetPlatform, using fallback plans');
      print('🔍 Returning fallback plans with ${fallbackPlans.length} plans');
      // Fallback plans for unsupported platforms (web, desktop, etc.)
      result = fallbackPlans;
    }
    
    print('🔍 Final premium plans result: ${result.length} plans');
    print('🔍 Plan keys: ${result.keys.toList()}');
    return result;
  }

  // Initialize billing service
  static Future<bool> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        print('In-app purchases not available');
        return false;
      }

      // Load products
      await loadProducts();
      
      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('Error in purchase stream: $error'),
      );

      return true;
    } catch (e) {
      print('Error initializing billing service: $e');
      return false;
    }
  }

  // Load available products
  static Future<void> loadProducts() async {
    try {
      final Set<String> productIds = _productIds;

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('Loaded ${_products.length} products for ${defaultTargetPlatform}');
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  // Get available products
  static List<ProductDetails> getProducts() {
    return _products;
  }

  // Get premium plans with pricing
  static List<Map<String, dynamic>> getPremiumPlans() {
    List<Map<String, dynamic>> plans = [];
    
    print('🔍 Getting premium plans for platform: $defaultTargetPlatform');
    print('🔍 Platform type: ${defaultTargetPlatform.runtimeType}');
    print('🔍 Available product IDs: ${_productIds}');
    print('🔍 Premium plans keys: ${_premiumPlans.keys}');
    print('🔍 Loaded products count: ${_products.length}');
    print('🔍 Premium plans map: $_premiumPlans');
    
    // For unsupported platforms (web, desktop), always return fallback plans
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      print('🔍 Platform not supported, returning fallback plans for: $defaultTargetPlatform');
      return [
        {
          'id': 'fallback_monthly',
          'name': 'Monthly Premium',
          'price': 9.99,
          'display_price': 9.99,
          'currency': 'USD',
          'period': 'month',
          'duration_days': 30,
        },
        {
          'id': 'fallback_yearly',
          'name': 'Yearly Premium',
          'price': 99.99,
          'display_price': 99.99,
          'currency': 'USD',
          'period': 'year',
          'duration_days': 365,
        },
      ];
    }
    
    // Check if _premiumPlans is empty (shouldn't happen for Android/iOS)
    if (_premiumPlans.isEmpty) {
      print('❌ ERROR: _premiumPlans is empty! This means no plans are configured for platform: $defaultTargetPlatform');
      print('❌ Available platforms: Android=${defaultTargetPlatform == TargetPlatform.android}, iOS=${defaultTargetPlatform == TargetPlatform.iOS}');
      
      // Return fallback plans instead of empty list
      print('🔍 Returning fallback plans due to empty premium plans');
      return [
        {
          'id': 'fallback_monthly',
          'name': 'Monthly Premium',
          'price': 9.99,
          'display_price': 9.99,
          'currency': 'USD',
          'period': 'month',
          'duration_days': 30,
        },
        {
          'id': 'fallback_yearly',
          'name': 'Yearly Premium',
          'price': 99.99,
          'display_price': 99.99,
          'currency': 'USD',
          'period': 'year',
          'duration_days': 365,
        },
      ];
    }
    
    for (String productId in _premiumPlans.keys) {
      final plan = _premiumPlans[productId]!;
      print('🔍 Processing plan: $productId - ${plan['name']}');
      
      ProductDetails product;
      try {
        product = _products.firstWhere((p) => p.id == productId);
      } catch (e) {
        print('🔍 Product not found in store, using fallback for: $productId');
        // Create a fallback product details object
        // For now, just use the base ProductDetails for both platforms
        product = ProductDetails(
          id: productId,
          title: plan['name'],
          description: '',
          rawPrice: double.parse(plan['price'].toString()),
          price: plan['price'].toString(),
          currencyCode: 'USD',
        );
      }
      
      plans.add({
        'id': productId,
        'name': plan['name'],
        'price': plan['price'],
        'display_price': product.rawPrice,
        'currency': product.currencyCode,
        'period': plan['period'],
        'duration_days': plan['duration_days'],
        'savings': plan['savings'],
        'product_details': product,
      });
      
      print('🔍 Added plan: ${plan['name']} - \$${plan['price']}/${plan['period']}');
    }
    
    print('🔍 Total plans returned: ${plans.length}');
    
    // If no plans were found, return fallback plans
    if (plans.isEmpty) {
      print('⚠️ No plans found, returning fallback plans');
      return [
        {
          'id': 'fallback_monthly',
          'name': 'Monthly Premium',
          'price': 9.99,
          'display_price': 9.99,
          'currency': 'USD',
          'period': 'month',
          'duration_days': 30,
        },
        {
          'id': 'fallback_yearly',
          'name': 'Yearly Premium',
          'price': 99.99,
          'display_price': 99.99,
          'currency': 'USD',
          'period': 'year',
          'duration_days': 365,
        },
      ];
    }
    
    return plans;
  }

  // Purchase a product
  static Future<bool> purchaseProduct(String productId) async {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      bool success = false;
      
      // Check if it's a subscription product
      final isSubscription = productId == _monthlyPremiumIdAndroid || 
                            productId == _yearlyPremiumIdAndroid ||
                            productId == _monthlyPremiumIdIOS || 
                            productId == _yearlyPremiumIdIOS;
      
      if (isSubscription) {
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }

      return success;
    } catch (e) {
      print('Error purchasing product $productId: $e');
      return false;
    }
  }

  // Handle purchase updates
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  // Handle individual purchase
  static Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        print('Purchase completed: ${purchaseDetails.productID}');
        
        // Verify purchase with backend
        final success = await _verifyPurchase(purchaseDetails);
        
        if (success) {
          // Complete the purchase
          await _inAppPurchase.completePurchase(purchaseDetails);
          
          // Update premium status
          await _updatePremiumStatus(purchaseDetails.productID);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        print('Purchase canceled: ${purchaseDetails.productID}');
      }
    } catch (e) {
      print('Error handling purchase: $e');
    }
  }

  // Verify purchase with backend
  static Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      
      final response = await http.post(
        Uri.parse('$_baseUrl/billing/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'purchaseToken': purchaseDetails.purchaseID,
          'productId': purchaseDetails.productID,
          'platform': platform,
          'receipt_data': purchaseDetails.verificationData.serverVerificationData,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying purchase: $e');
      return false;
    }
  }

  // Update premium status after successful purchase
  static Future<void> _updatePremiumStatus(String productId) async {
    try {
      final plan = _premiumPlans[productId];
      if (plan == null) return;

      final prefs = await SharedPreferences.getInstance();
      
      // Set premium status using the same key as PremiumService
      await prefs.setBool('premium_status', true);
      
      // Calculate expiry date
      final expiryDate = DateTime.now().add(Duration(days: plan['duration_days']));
      await prefs.setString('premium_expiry', expiryDate.toIso8601String());
      
      // Store purchase info
      await prefs.setString('premium_product_id', productId);
      await prefs.setString('premium_purchase_date', DateTime.now().toIso8601String());
      
      print('✅ Premium status updated for product: $productId');
      print('✅ Expiry date: ${expiryDate.toIso8601String()}');
    } catch (e) {
      print('❌ Error updating premium status: $e');
    }
  }

  // Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  // Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final premiumStatus = prefs.getBool('premium_status') ?? false;
      
      if (!premiumStatus) {
        print('🔍 Premium status: false');
        return false;
      }
      
      final expiryDate = prefs.getString('premium_expiry');
      if (expiryDate == null) {
        print('🔍 No expiry date found');
        return false;
      }
      
      final expiry = DateTime.parse(expiryDate);
      final isActive = DateTime.now().isBefore(expiry);
      
      print('🔍 Premium status: $premiumStatus, Expiry: $expiryDate, Active: $isActive');
      return isActive;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return false;
    }
  }

  // Get subscription expiry date
  static Future<DateTime?> getSubscriptionExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryDate = prefs.getString('premium_expiry');
      return expiryDate != null ? DateTime.parse(expiryDate) : null;
    } catch (e) {
      print('Error getting subscription expiry: $e');
      return null;
    }
  }

  // Cancel subscription
  static Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$_baseUrl/billing/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to cancel subscription');
      }
    } catch (e) {
      print('Cancel subscription error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Dispose resources
  static void dispose() {
    _subscription?.cancel();
  }

  // Check if billing is available
  static bool get isAvailable => _isAvailable;
  
  // Get current platform
  static String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android';
} 