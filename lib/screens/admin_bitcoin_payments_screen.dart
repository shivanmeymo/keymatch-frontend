import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import '../constants/colors.dart';
import '../constants/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/themed_text.dart';

class AdminBitcoinPaymentsScreen extends StatefulWidget {
  const AdminBitcoinPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminBitcoinPaymentsScreen> createState() => _AdminBitcoinPaymentsScreenState();
}

class _AdminBitcoinPaymentsScreenState extends State<AdminBitcoinPaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    // Refresh payments every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadPayments();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/billing/bitcoin/admin/payments'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _payments = List<Map<String, dynamic>>.from(data['payments']);
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        throw Exception('Failed to load payments: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load payments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmPayment(String paymentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/billing/bitcoin/admin/confirm/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment confirmed successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        _loadPayments(); // Refresh the list
      } else {
        throw Exception('Failed to confirm payment: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyPaymentOnBlockchain(String address, double expectedAmount) async {
    try {
      // Open blockchain explorer in browser
      final url = 'https://www.blockchain.com/explorer/addresses/btc/$address';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open blockchain explorer')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening blockchain explorer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ThemedText('Bitcoin Payment Verification'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildPaymentsList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          ThemedText(
            _errorMessage!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPayments,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    if (_payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.accentGreen, size: 64),
            SizedBox(height: 16),
            ThemedText(
              'No pending Bitcoin payments',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] ?? 'pending';
    final isConfirmed = status == 'confirmed';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ThemedText(
                  'Payment ID: ${payment['paymentId']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfirmed ? AppColors.accentGreen : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ThemedText(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // User info
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: ThemedText(
                    'User: ${payment['userEmail']} (ID: ${payment['userId']})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Bitcoin address
            Row(
              children: [
                const Icon(Icons.currency_bitcoin, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: ThemedText(
                    'Address: ${payment['address']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Amount
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16),
                const SizedBox(width: 8),
                ThemedText(
                  'Expected Amount: ${payment['expectedAmount']} BTC',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Created date
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 8),
                ThemedText(
                  'Created: ${DateTime.parse(payment['createdAt']).toLocal().toString().substring(0, 19)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            
            if (payment['subscriptionEndDate']) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event, size: 16),
                  const SizedBox(width: 8),
                  ThemedText(
                    'Expires: ${DateTime.parse(payment['subscriptionEndDate']).toLocal().toString().substring(0, 19)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (!isConfirmed) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyPaymentOnBlockchain(
                        payment['address'],
                        payment['expectedAmount'],
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Verify on Blockchain'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmPayment(payment['paymentId']),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.accentGreen),
                    SizedBox(width: 8),
                    ThemedText(
                      'Payment confirmed and subscription active',
                      style: TextStyle(color: AppColors.accentGreen),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 