import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import '../utils/flavor_helper.dart';

enum PaymentMethod {
  stripe,
  bitcoin,
  googlePlay,
}

enum SubscriptionTier {
  free,
  premium,
  enterprise,
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// Get the appropriate payment screen based on current flavor
  static Future<Widget> getPaymentScreen({
    required String productId,
    required String productName,
    required double price,
    required VoidCallback onSuccess,
    required VoidCallback onCancel,
  }) async {
    final flavor = await FlavorHelper.getCurrentFlavor();
    
    switch (flavor) {
      case Flavor.playstore:
        return GooglePlayPaymentScreen(
          productId: productId,
          productName: productName,
          price: price,
          onSuccess: onSuccess,
          onCancel: onCancel,
        );
      case Flavor.fdroid:
        return FDroidPaymentScreen(
          productId: productId,
          productName: productName,
          price: price,
          onSuccess: onSuccess,
          onCancel: onCancel,
        );
    }
  }

  /// Get available payment methods for current flavor
  static Future<List<PaymentMethod>> getAvailablePaymentMethods() async {
    return await FlavorHelper.getAvailablePaymentMethods();
  }

  /// Check if a specific payment method is available
  static Future<bool> isPaymentMethodAvailable(PaymentMethod method) async {
    return await FlavorHelper.isPaymentMethodAvailable(method);
  }

  // Legacy methods for backward compatibility
  static Future<Map<String, dynamic>> createStripePaymentIntent(
    SubscriptionTier tier,
    String currency,
  ) async {
    // TODO: Implement Stripe payment intent creation
    throw UnimplementedError('Stripe payment not implemented yet');
  }

  static Future<Map<String, dynamic>> getBitcoinPaymentInfo(
    SubscriptionTier tier,
  ) async {
    // TODO: Implement Bitcoin payment info
    throw UnimplementedError('Bitcoin payment not implemented yet');
  }

  static Future<SubscriptionTier> getCurrentTier() async {
    // TODO: Implement subscription tier detection
    return SubscriptionTier.free;
  }
}

/// Google Play Payment Screen (Play Store flavor only)
class GooglePlayPaymentScreen extends StatelessWidget {
  final String productId;
  final String productName;
  final double price;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const GooglePlayPaymentScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Play Payment'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.payment,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              productName,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'This purchase will be processed through Google Play Billing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement Google Play Billing
                onSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Pay with Google Play',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

/// F-Droid Payment Screen (F-Droid flavor only)
class FDroidPaymentScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final double price;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const FDroidPaymentScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<FDroidPaymentScreen> createState() => _FDroidPaymentScreenState();
}

class _FDroidPaymentScreenState extends State<FDroidPaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.stripe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Options'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.productName,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${widget.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Payment Method Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Payment Method',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Stripe Option
                    RadioListTile<PaymentMethod>(
                      title: const Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Credit Card (Stripe)'),
                        ],
                      ),
                      value: PaymentMethod.stripe,
                      groupValue: _selectedMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                    ),
                    
                    // Bitcoin Option
                    RadioListTile<PaymentMethod>(
                      title: const Row(
                        children: [
                          Icon(Icons.currency_bitcoin, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Bitcoin'),
                        ],
                      ),
                      value: PaymentMethod.bitcoin,
                      groupValue: _selectedMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Payment Button
            ElevatedButton(
              onPressed: () {
                _processPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedMethod == PaymentMethod.stripe 
                    ? Colors.blue 
                    : Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _selectedMethod == PaymentMethod.stripe 
                    ? 'Pay with Card' 
                    : 'Pay with Bitcoin',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() {
    switch (_selectedMethod) {
      case PaymentMethod.stripe:
        // TODO: Implement Stripe payment
        _showStripePayment();
        break;
      case PaymentMethod.bitcoin:
        // TODO: Implement Bitcoin payment
        _showBitcoinPayment();
        break;
      default:
        break;
    }
  }

  void _showStripePayment() {
    // TODO: Navigate to Stripe payment screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stripe payment not implemented yet')),
    );
  }

  void _showBitcoinPayment() {
    // TODO: Navigate to Bitcoin payment screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bitcoin payment not implemented yet')),
    );
  }
} 