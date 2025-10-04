import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/colors.dart';
import '../constants/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/themed_text.dart';

class StripePaymentWidget extends StatefulWidget {
  final String planId;
  final String planName;
  final double amount;
  final String currency;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const StripePaymentWidget({
    Key? key,
    required this.planId,
    required this.planName,
    required this.amount,
    this.currency = 'USD',
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<StripePaymentWidget> createState() => _StripePaymentWidgetState();
}

class _StripePaymentWidgetState extends State<StripePaymentWidget> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _paymentIntentId;
  String? _clientSecret;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      // Stripe is already initialized in main.dart
      // This method is kept for future use if needed
    } catch (e) {
      print('Error initializing Stripe: $e');
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create payment intent on the server
      final paymentIntentData = await _createPaymentIntent();
      _paymentIntentId = paymentIntentData['paymentIntentId'];
      _clientSecret = paymentIntentData['clientSecret'];

      // Step 2: Present payment sheet
      await _presentPaymentSheet();

      // Step 3: Confirm payment on server
      await _confirmPayment();

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Your subscription is now active.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: $e';
      });

      if (widget.onError != null) {
        widget.onError!();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/billing/stripe/create-payment-intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'tier': widget.planId,
        'amount': (widget.amount * 100).round(), // Convert to cents
        'currency': widget.currency,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create payment intent: ${response.body}');
    }
  }

  Future<void> _presentPaymentSheet() async {
    if (_clientSecret == null) {
      throw Exception('No client secret available');
    }

    // Configure payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: _clientSecret!,
        merchantDisplayName: 'KeyMatch',
        style: ThemeMode.light,
      ),
    );

    // Present payment sheet
    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> _confirmPayment() async {
    if (_paymentIntentId == null) {
      throw Exception('No payment intent ID available');
    }

    final token = await AuthService.getToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/billing/stripe/confirm-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'paymentIntentId': _paymentIntentId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to confirm payment: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.credit_card, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            ThemedText(
              'Pay with Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Plan information
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedText(
                widget.planName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ThemedText(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  ThemedText(
                    '\$${widget.amount.toStringAsFixed(2)} ${widget.currency}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Error message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: ThemedText(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Pay button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const ThemedText(
                    'Pay with Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Security notice
        Row(
          children: [
            Icon(Icons.security, color: Colors.grey.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: ThemedText(
                'Your payment information is secure and encrypted by Stripe',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Stripe powered notice
        Row(
          children: [
            Icon(Icons.verified, color: Colors.grey.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: ThemedText(
                'Powered by Stripe - PCI DSS compliant',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 
