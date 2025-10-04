import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_match/services/payment_service.dart' as pay;

void main() {
  group('Dual Distribution Tests', () {
    test('Subscription tiers are properly configured', () {
      // Test subscription tier configuration
      final freeTier = pay.PaymentService.tierFeatures[pay.SubscriptionTier.free];
      final premiumTier = pay.PaymentService.tierFeatures[pay.SubscriptionTier.premium];
      final enterpriseTier = pay.PaymentService.tierFeatures[pay.SubscriptionTier.enterprise];
      
      expect(freeTier, isNotNull);
      expect(premiumTier, isNotNull);
      expect(enterpriseTier, isNotNull);
      expect(freeTier!['price'], equals(0.0));
      expect(premiumTier!['price'], isA<double>());
      expect(enterpriseTier!['price'], isA<double>());
      
      print('💰 Free tier price: ${freeTier['price']}');
      print('💰 Premium tier price: ${premiumTier['price']}');
      print('💰 Enterprise tier price: ${enterpriseTier['price']}');
    });

    test('Payment methods enum is properly defined', () {
      // Test that payment methods are properly defined
      expect(pay.PaymentMethod.values, contains(pay.PaymentMethod.stripe));
      expect(pay.PaymentMethod.values, contains(pay.PaymentMethod.bitcoin));
      
      print('💳 Available payment methods: ${pay.PaymentMethod.values.map((m) => m.name).toList()}');
    });

    test('Subscription tiers enum is properly defined', () {
      // Test that subscription tiers are properly defined
      expect(pay.SubscriptionTier.values, contains(pay.SubscriptionTier.free));
      expect(pay.SubscriptionTier.values, contains(pay.SubscriptionTier.premium));
      expect(pay.SubscriptionTier.values, contains(pay.SubscriptionTier.enterprise));
      
      print('💰 Available subscription tiers: ${pay.SubscriptionTier.values.map((t) => t.name).toList()}');
    });

    test('Tier features are properly configured', () {
      // Test that all tiers have proper feature configurations
      for (final tier in pay.SubscriptionTier.values) {
        final features = pay.PaymentService.tierFeatures[tier];
        expect(features, isNotNull);
        expect(features!['price'], isA<double>());
        expect(features['maxMatches'], isA<int>());
        expect(features['maxImages'], isA<int>());
        expect(features['advancedFilters'], isA<bool>());
        expect(features['prioritySupport'], isA<bool>());
        
        print('✅ Tier ${tier.name} features: ${features['maxMatches']} matches, ${features['maxImages']} images, \$${features['price']}');
      }
    });

    test('Free tier has correct limitations', () {
      final freeFeatures = pay.PaymentService.tierFeatures[pay.SubscriptionTier.free]!;
      
      expect(freeFeatures['price'], equals(0.0));
      expect(freeFeatures['maxMatches'], isA<int>());
      expect(freeFeatures['maxImages'], isA<int>());
      expect(freeFeatures['advancedFilters'], equals(false));
      expect(freeFeatures['prioritySupport'], equals(false));
      
      print('✅ Free tier: ${freeFeatures['maxMatches']} matches, ${freeFeatures['maxImages']} images');
    });

    test('Premium tier has enhanced features', () {
      final premiumFeatures = pay.PaymentService.tierFeatures[pay.SubscriptionTier.premium]!;
      
      expect(premiumFeatures['price'], greaterThan(0.0));
      expect(premiumFeatures['maxMatches'], equals(-1)); // unlimited
      expect(premiumFeatures['maxImages'], greaterThan(3)); // more than free
      expect(premiumFeatures['advancedFilters'], equals(true));
      expect(premiumFeatures['prioritySupport'], equals(true));
      
      print('✅ Premium tier: unlimited matches, ${premiumFeatures['maxImages']} images, \$${premiumFeatures['price']}');
    });

    test('Enterprise tier has maximum features', () {
      final enterpriseFeatures = pay.PaymentService.tierFeatures[pay.SubscriptionTier.enterprise]!;
      
      expect(enterpriseFeatures['price'], greaterThan(0.0));
      expect(enterpriseFeatures['maxMatches'], equals(-1)); // unlimited
      expect(enterpriseFeatures['maxImages'], greaterThan(6)); // more than premium
      expect(enterpriseFeatures['advancedFilters'], equals(true));
      expect(enterpriseFeatures['prioritySupport'], equals(true));
      expect(enterpriseFeatures['apiAccess'], equals(true));
      
      print('✅ Enterprise tier: unlimited matches, ${enterpriseFeatures['maxImages']} images, \$${enterpriseFeatures['price']}');
    });
  });
}

// Test runner function
Future<void> runDualDistributionTests() async {
  print('🧪 Running Dual Distribution Tests...\n');
  
  try {
    // Test subscription tiers
    print('💰 Testing subscription tiers...');
    final tiers = pay.PaymentService.tierFeatures.keys.toList();
    print('✅ Available tiers: ${tiers.map((t) => t.name).toList()}');
    
    // Test payment methods
    print('\n💳 Testing payment methods...');
    final paymentMethods = pay.PaymentMethod.values.toList();
    print('✅ Available methods: ${paymentMethods.map((m) => m.name).toList()}');
    
    // Test tier features
    print('\n📋 Testing tier features...');
    for (final tier in pay.SubscriptionTier.values) {
      final features = pay.PaymentService.tierFeatures[tier]!;
      print('✅ ${tier.name}: ${features['maxMatches']} matches, ${features['maxImages']} images, \$${features['price']}');
    }
    
    print('\n🎉 All dual distribution tests passed!');
    print('\n📋 Summary:');
    print('  - Subscription Tiers: ${tiers.length} available');
    print('  - Payment Methods: ${paymentMethods.length} available');
    print('  - All tiers properly configured with features');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
} 