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

class BillingService {
  static const String _baseUrl = 'https://key-match-dating-app-a069d14fdf4a.herokuapp.com';
  
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
    if (defaultTargetPlatform == TargetPlatform.android) {
      return {
        _monthlyPremiumIdAndroid,
        _yearlyPremiumIdAndroid,
        _boostPackIdAndroid,
        _superLikePackIdAndroid,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return {
        _monthlyPremiumIdIOS,
        _yearlyPremiumIdIOS,
        _boostPackIdIOS,
        _superLikePackIdIOS,
      };
    }
    return {};
  }
  
  // Premium plans configuration
  static Map<String, Map<String, dynamic>> get _premiumPlans {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return {
        _monthlyPremiumIdAndroid: {
          'name': 'Monthly Premium',
          'price': 9.99,
          'period': 'month',
          'duration_days': 30,
          'features': [
            'Unlimited likes',
            'Advanced filters',
            'Read receipts',
            'See who likes you',
            'Priority in matching',
          ],
        },
        _yearlyPremiumIdAndroid: {
          'name': 'Yearly Premium',
          'price': 99.99,
          'period': 'year',
          'duration_days': 365,
          'original_price': 119.88,
          'savings': 'Save 17%',
          'features': [
            'All monthly features',
            'Priority support',
            'Exclusive events',
            'Profile boost',
          ],
        },
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return {
        _monthlyPremiumIdIOS: {
          'name': 'Monthly Premium',
          'price': 9.99,
          'period': 'month',
          'duration_days': 30,
          'features': [
            'Unlimited likes',
            'Advanced filters',
            'Read receipts',
            'See who likes you',
            'Priority in matching',
          ],
        },
        _yearlyPremiumIdIOS: {
          'name': 'Yearly Premium',
          'price': 99.99,
          'period': 'year',
          'duration_days': 365,
          'original_price': 119.88,
          'savings': 'Save 17%',
          'features': [
            'All monthly features',
            'Priority support',
            'Exclusive events',
            'Profile boost',
          ],
        },
      };
    }
    return {};
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
    
    for (String productId in _premiumPlans.keys) {
      final plan = _premiumPlans[productId]!;
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => ProductDetails(
          id: productId,
          title: plan['name'],
          description: '',
          rawPrice: double.parse(plan['price'].toString()),
          price: plan['price'].toString(),
          currencyCode: defaultTargetPlatform == TargetPlatform.iOS ? 'USD' : 'USD',
        ),
      );
      
      plans.add({
        'id': productId,
        'name': plan['name'],
        'price': plan['price'],
        'display_price': product.rawPrice,
        'currency': product.currencyCode,
        'period': plan['period'],
        'duration_days': plan['duration_days'],
        'features': plan['features'],
        'original_price': plan['original_price'],
        'savings': plan['savings'],
        'product_details': product,
      });
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
        Uri.parse('$_baseUrl/api/billing/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_id': purchaseDetails.productID,
          'purchase_token': purchaseDetails.purchaseID,
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

  // Cancel subscription (for testing)
  static Future<bool> cancelSubscription() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/billing/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('premium_status', false);
        await prefs.remove('premium_expiry');
        await prefs.remove('premium_product_id');
        await prefs.remove('premium_purchase_date');
        print('✅ Subscription cancelled successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
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