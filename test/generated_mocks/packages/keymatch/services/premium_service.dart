import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'billing_service.dart';

class PremiumService {
  static const String _premiumStatusKey = 'premium_status';
  static const String _premiumExpiryKey = 'premium_expiry';
  static const String _freeLikesUsedKey = 'free_likes_used';
  static const String _lastLikeResetKey = 'last_like_reset';
  
  static String get baseUrl => 'https://key-match-dating-app-a069d14fdf4a.herokuapp.com';

  // Premium features configuration
  static const Map<String, dynamic> _premiumFeatures = {
    'unlimited_likes': {
      'name': 'Unlimited Likes',
      'description': 'Like as many profiles as you want',
      'free_limit': 10,
      'free_reset_days': 1, // Reset every day
    },
    'advanced_filters': {
      'name': 'Advanced Filters',
      'description': 'Filter by age, location, and more',
      'premium_only': true,
    },
    'read_receipts': {
      'name': 'Read Receipts',
      'description': 'See when your messages are read',
      'premium_only': true,
    },
    'see_who_likes_you': {
      'name': 'See Who Likes You',
      'description': 'See who has liked your profile',
      'premium_only': true,
    },
    'priority_matching': {
      'name': 'Priority Matching',
      'description': 'Get priority in the matching algorithm',
      'premium_only': true,
    },
  };

  // Check if user has premium
  static Future<bool> isPremium() async {
    try {
      // First check billing service for active subscription
      final hasSubscription = await BillingService.hasActiveSubscription();
      if (hasSubscription) return true;
      
      // Fallback to local storage check
      final prefs = await SharedPreferences.getInstance();
      final premiumStatus = prefs.getBool(_premiumStatusKey) ?? false;
      
      if (premiumStatus) {
        // Check if premium has expired
        final expiryDate = prefs.getString(_premiumExpiryKey);
        if (expiryDate != null) {
          final expiry = DateTime.parse(expiryDate);
          if (DateTime.now().isAfter(expiry)) {
            // Premium has expired
            await _setPremiumStatus(false);
            return false;
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Get premium expiry date
  static Future<DateTime?> getPremiumExpiry() async {
    try {
      // First check billing service
      final billingExpiry = await BillingService.getSubscriptionExpiry();
      if (billingExpiry != null) return billingExpiry;
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final expiryDate = prefs.getString(_premiumExpiryKey);
      return expiryDate != null ? DateTime.parse(expiryDate) : null;
    } catch (e) {
      print('Error getting premium expiry: $e');
      return null;
    }
  }

  // Set premium status
  static Future<void> _setPremiumStatus(bool isPremium, {DateTime? expiryDate}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumStatusKey, isPremium);
      if (expiryDate != null) {
        await prefs.setString(_premiumExpiryKey, expiryDate.toIso8601String());
      }
    } catch (e) {
      print('Error setting premium status: $e');
    }
  }

  // Check if a feature is available
  static Future<bool> isFeatureAvailable(String featureKey) async {
    try {
      final isPremiumUser = await isPremium();
      final feature = _premiumFeatures[featureKey];
      
      if (feature == null) return false;
      
      // If it's premium only and user is not premium
      if (feature['premium_only'] == true && !isPremiumUser) {
        return false;
      }
      
      // If it has a free limit, check usage
      if (feature['free_limit'] != null) {
        return await _checkFreeFeatureUsage(featureKey, feature);
      }
      
      return true;
    } catch (e) {
      print('Error checking feature availability: $e');
      return false;
    }
  }

  // Check free feature usage
  static Future<bool> _checkFreeFeatureUsage(String featureKey, Map<String, dynamic> feature) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final used = prefs.getInt('${featureKey}_used') ?? 0;
      final lastReset = prefs.getString('${featureKey}_last_reset');
      
      // Check if we need to reset the counter
      if (lastReset != null) {
        final lastResetDate = DateTime.parse(lastReset);
        final resetDays = feature['free_reset_days'] ?? 1;
        final nextReset = lastResetDate.add(Duration(days: resetDays));
        
        if (DateTime.now().isAfter(nextReset)) {
          // Reset the counter
          await prefs.setInt('${featureKey}_used', 0);
          await prefs.setString('${featureKey}_last_reset', DateTime.now().toIso8601String());
          return true;
        }
      } else {
        // First time using this feature
        await prefs.setString('${featureKey}_last_reset', DateTime.now().toIso8601String());
      }
      
      return used < feature['free_limit'];
    } catch (e) {
      print('Error checking free feature usage: $e');
      return false;
    }
  }

  // Use a feature (increment usage counter)
  static Future<void> useFeature(String featureKey) async {
    try {
      // Check if user has premium
      final isPremiumUser = await isPremium();
      
      // If user has premium, don't increment the counter
      if (isPremiumUser) {
        print('Premium user - not incrementing $featureKey counter');
        return;
      }
      
      // Only increment counter for non-premium users
      final prefs = await SharedPreferences.getInstance();
      final used = prefs.getInt('${featureKey}_used') ?? 0;
      await prefs.setInt('${featureKey}_used', used + 1);
      print('Non-premium user - incremented $featureKey counter to ${used + 1}');
    } catch (e) {
      print('Error using feature: $e');
    }
  }

  // Get feature usage info
  static Future<Map<String, dynamic>> getFeatureUsage(String featureKey) async {
    try {
      final feature = _premiumFeatures[featureKey];
      if (feature == null) return {};
      
      final isPremiumUser = await isPremium();
      final isAvailable = await isFeatureAvailable(featureKey);
      
      if (feature['premium_only'] == true) {
        return {
          'available': isPremiumUser,
          'premium_only': true,
          'name': feature['name'],
          'description': feature['description'],
        };
      }
      
      if (feature['free_limit'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final used = prefs.getInt('${featureKey}_used') ?? 0;
        final remaining = feature['free_limit'] - used;
        
        return {
          'available': isAvailable,
          'premium_only': false,
          'name': feature['name'],
          'description': feature['description'],
          'used': used,
          'limit': feature['free_limit'],
          'remaining': remaining > 0 ? remaining : 0,
          'reset_days': feature['free_reset_days'],
        };
      }
      
      return {
        'available': isAvailable,
        'premium_only': false,
        'name': feature['name'],
        'description': feature['description'],
      };
    } catch (e) {
      print('Error getting feature usage: $e');
      return {};
    }
  }

  // Get all features info
  static Future<List<Map<String, dynamic>>> getAllFeatures() async {
    try {
      List<Map<String, dynamic>> features = [];
      
      for (String key in _premiumFeatures.keys) {
        final usage = await getFeatureUsage(key);
        if (usage.isNotEmpty) {
          features.add({
            'key': key,
            ...usage,
          });
        }
      }
      
      return features;
    } catch (e) {
      print('Error getting all features: $e');
      return [];
    }
  }

  // Purchase premium using billing service
  static Future<bool> purchasePremium(String productId) async {
    try {
      return await BillingService.purchaseProduct(productId);
    } catch (e) {
      print('Error purchasing premium: $e');
      return false;
    }
  }

  // Get premium plans from billing service
  static Future<List<Map<String, dynamic>>> getPremiumPlans() async {
    try {
      return BillingService.getPremiumPlans();
    } catch (e) {
      print('Error getting premium plans: $e');
      return [];
    }
  }

  // Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      return await BillingService.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  // Cancel premium subscription
  static Future<bool> cancelPremium() async {
    try {
      return await BillingService.cancelSubscription();
    } catch (e) {
      print('Error canceling premium: $e');
      return false;
    }
  }

  // Check if billing is available
  static bool get isBillingAvailable => BillingService.isAvailable;

  // Manual premium status setting for testing
  static Future<void> setPremiumStatus(bool isPremium, {int days = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (isPremium) {
        final expiryDate = DateTime.now().add(Duration(days: days));
        await prefs.setBool(_premiumStatusKey, true);
        await prefs.setString(_premiumExpiryKey, expiryDate.toIso8601String());
        print('✅ Premium status set to true, expires: ${expiryDate.toIso8601String()}');
      } else {
        await prefs.setBool(_premiumStatusKey, false);
        await prefs.remove(_premiumExpiryKey);
        print('✅ Premium status set to false');
      }
    } catch (e) {
      print('❌ Error setting premium status: $e');
    }
  }

  // Clear all premium data (for testing)
  static Future<void> clearPremiumData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_premiumStatusKey);
      await prefs.remove(_premiumExpiryKey);
      await prefs.remove(_freeLikesUsedKey);
      await prefs.remove(_lastLikeResetKey);
      
      // Clear feature usage counters
      for (String featureKey in _premiumFeatures.keys) {
        await prefs.remove('${featureKey}_used');
        await prefs.remove('${featureKey}_last_reset');
      }
      
      print('✅ All premium data cleared');
    } catch (e) {
      print('❌ Error clearing premium data: $e');
    }
  }

  // Debug premium status
  static Future<void> debugPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final premiumStatus = prefs.getBool(_premiumStatusKey);
      final expiryDate = prefs.getString(_premiumExpiryKey);
      final billingStatus = await BillingService.hasActiveSubscription();
      
      print('🔍 === Premium Status Debug ===');
      print('🔍 Local premium status: $premiumStatus');
      print('🔍 Local expiry date: $expiryDate');
      print('🔍 Billing service status: $billingStatus');
      print('🔍 Combined isPremium result: ${await isPremium()}');
      
      if (expiryDate != null) {
        final expiry = DateTime.parse(expiryDate);
        final isExpired = DateTime.now().isAfter(expiry);
        print('🔍 Expiry date parsed: $expiry');
        print('🔍 Is expired: $isExpired');
      }
      
      print('🔍 === End Debug ===');
    } catch (e) {
      print('❌ Error debugging premium status: $e');
    }
  }
} 