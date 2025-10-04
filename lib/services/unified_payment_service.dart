import 'dart:async';
import 'package:flutter/foundation.dart';
import 'billing_service.dart';
import 'payment_service.dart' as pay;
import '../utils/flavor_helper.dart';

enum PaymentProvider {
  googlePlayBilling,
  stripe,
  bitcoin,
}

class UnifiedPaymentService {
  static bool _isInitialized = false;
  static PaymentProvider? _preferredProvider;

  /// Initialize the unified payment service
  static Future<void> initialize() async {
    print('💳 DEBUG: UnifiedPaymentService.initialize() called');
    if (_isInitialized) {
      print('💳 DEBUG: Already initialized, returning');
      return;
    }

    try {
      print('💳 DEBUG: Determining preferred provider...');
      // Determine preferred payment provider using FlavorHelper
      _preferredProvider = await _determinePreferredProvider();
      
      // Initialize appropriate billing service
      if (_preferredProvider == PaymentProvider.googlePlayBilling) {
        print('💳 DEBUG: Initializing Google Play Billing...');
        await BillingService.initialize();
      }
      
      _isInitialized = true;
      print('💳 Unified Payment Service initialized with provider: $_preferredProvider');
    } catch (e) {
      print('Error initializing unified payment service: $e');
      _preferredProvider = PaymentProvider.stripe; // Fallback
    }
  }

  /// Get the preferred payment provider for the current platform
  static PaymentProvider get preferredProvider {
    if (!_isInitialized) {
      print('⚠️ UnifiedPaymentService not initialized. Call initialize() first.');
      return PaymentProvider.stripe;
    }
    return _preferredProvider ?? PaymentProvider.stripe;
  }

  /// Get available payment providers for the current platform
  static Future<List<PaymentProvider>> getAvailableProviders() async {
    if (!_isInitialized) {
      return [PaymentProvider.bitcoin, PaymentProvider.stripe];
    }

    final providers = <PaymentProvider>[];
    
    // Use FlavorHelper to detect the current flavor
    final currentFlavor = await FlavorHelper.getCurrentFlavor();
    
    if (currentFlavor == Flavor.playstore) {
      providers.add(PaymentProvider.googlePlayBilling);
      // For Play Store, only use Google Play Billing
      return providers;
    }
    
    // For F-Droid, prioritize Bitcoin
    if (currentFlavor == Flavor.fdroid) {
      providers.addAll([
        PaymentProvider.bitcoin,  // Primary for F-Droid
        PaymentProvider.stripe,   // Secondary for F-Droid
      ]);
    } else {
      providers.addAll([
        PaymentProvider.stripe,   // Primary for other platforms
        PaymentProvider.bitcoin,  // Secondary for other platforms
      ]);
    }
    
    return providers;
  }

  /// Purchase a premium subscription
  static Future<PaymentResult> purchaseSubscription(pay.SubscriptionTier tier) async {
    await initialize();
    
    try {
      switch (preferredProvider) {
        case PaymentProvider.googlePlayBilling:
          return await _purchaseWithGooglePlayBilling(tier);
        case PaymentProvider.stripe:
          return await _purchaseWithStripe(tier);
        case PaymentProvider.bitcoin:
          return await _purchaseWithBitcoin(tier);
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Payment failed: $e',
        provider: preferredProvider,
      );
    }
  }

  /// Purchase with Google Play Billing
  static Future<PaymentResult> _purchaseWithGooglePlayBilling(pay.SubscriptionTier tier) async {
    try {
      final productId = _getGooglePlayProductId(tier);
      final success = await BillingService.purchaseProduct(productId);
      
      return PaymentResult(
        success: success,
        provider: PaymentProvider.googlePlayBilling,
        productId: productId,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Google Play Billing failed: $e',
        provider: PaymentProvider.googlePlayBilling,
      );
    }
  }

  /// Purchase with Stripe
  static Future<PaymentResult> _purchaseWithStripe(pay.SubscriptionTier tier) async {
    try {
      final paymentIntent = await pay.PaymentService.createStripePaymentIntent(tier, 'USD');
      // Handle Stripe payment flow here
      
      return PaymentResult(
        success: true,
        provider: PaymentProvider.stripe,
        paymentIntent: paymentIntent,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Stripe payment failed: $e',
        provider: PaymentProvider.stripe,
      );
    }
  }

  /// Purchase with Bitcoin
  static Future<PaymentResult> _purchaseWithBitcoin(pay.SubscriptionTier tier) async {
    try {
      final paymentInfo = await pay.PaymentService.getBitcoinPaymentInfo(tier);
      
      return PaymentResult(
        success: true,
        provider: PaymentProvider.bitcoin,
        paymentData: paymentInfo,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Bitcoin payment failed: $e',
        provider: PaymentProvider.bitcoin,
      );
    }
  }

  /// Get Google Play product ID for subscription tier
  static String _getGooglePlayProductId(pay.SubscriptionTier tier) {
    switch (tier) {
      case pay.SubscriptionTier.premium:
        return defaultTargetPlatform == TargetPlatform.android
            ? 'keymatch_monthly_premium'
            : 'keymatch_monthly_premium_ios';
      case pay.SubscriptionTier.enterprise:
        return defaultTargetPlatform == TargetPlatform.android
            ? 'keymatch_yearly_premium'
            : 'keymatch_yearly_premium_ios';
      case pay.SubscriptionTier.free:
        throw Exception('Cannot purchase free tier');
    }
  }

  /// Determine the preferred payment provider
  static Future<PaymentProvider> _determinePreferredProvider() async {
    print('💳 DEBUG: _determinePreferredProvider() called');
    // Use FlavorHelper to detect the current flavor
    print('💳 DEBUG: Calling FlavorHelper.getCurrentFlavor()...');
    final currentFlavor = await FlavorHelper.getCurrentFlavor();
    print('💳 DEBUG: FlavorHelper returned: $currentFlavor');
    
    if (currentFlavor == Flavor.playstore) {
      print('💳 Play Store flavor detected: Using Google Play Billing');
      return PaymentProvider.googlePlayBilling;
    }
    
    // For F-Droid, prefer Bitcoin
    if (currentFlavor == Flavor.fdroid) {
      print('💳 F-Droid flavor detected: Preferring Bitcoin payments');
      return PaymentProvider.bitcoin;
    }
    
    // Default to Stripe for other platforms
    print('💳 DEBUG: Defaulting to Stripe');
    return PaymentProvider.stripe;
  }

  /// Get subscription status
  static Future<bool> getSubscriptionStatus() async {
    await initialize();
    
    try {
      if (preferredProvider == PaymentProvider.googlePlayBilling) {
        return await BillingService.hasActiveSubscription();
      } else {
        final tier = await pay.PaymentService.getCurrentTier();
        return tier != pay.SubscriptionTier.free;
      }
    } catch (e) {
      print('Error getting subscription status: $e');
      return false;
    }
  }

  /// Restore purchases (Google Play Billing)
  static Future<bool> restorePurchases() async {
    await initialize();
    
    if (preferredProvider == PaymentProvider.googlePlayBilling) {
      return await BillingService.restorePurchases();
    }
    
    // For other providers, this might involve checking server-side
    return true;
  }

  /// Get platform-specific payment information
  static Future<Map<String, dynamic>> getPaymentInfo() async {
    final currentFlavor = await FlavorHelper.getCurrentFlavor();
    return {
      'preferredProvider': preferredProvider.name,
      'availableProviders': (await getAvailableProviders()).map((p) => p.name).toList(),
      'platform': currentFlavor.name,
      'isPlayStore': currentFlavor == Flavor.playstore,
      'isFdroid': currentFlavor == Flavor.fdroid,
    };
  }
}

/// Result of a payment operation
class PaymentResult {
  final bool success;
  final String? error;
  final PaymentProvider provider;
  final String? productId;
  final Map<String, dynamic>? paymentIntent;
  final Map<String, dynamic>? paymentData;

  PaymentResult({
    required this.success,
    this.error,
    required this.provider,
    this.productId,
    this.paymentIntent,
    this.paymentData,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, provider: $provider, error: $error)';
  }
} 