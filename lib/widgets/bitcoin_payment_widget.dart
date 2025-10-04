import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../constants/colors.dart';
import '../constants/api_config.dart';
import '../services/auth_service.dart';
import '../services/bitcoin_conversion_service.dart';
import '../widgets/themed_text.dart';

class BitcoinPaymentWidget extends StatefulWidget {
  final String planId;
  final String planName;
  final double amount;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const BitcoinPaymentWidget({
    Key? key,
    required this.planId,
    required this.planName,
    required this.amount,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<BitcoinPaymentWidget> createState() => _BitcoinPaymentWidgetState();
}

class _BitcoinPaymentWidgetState extends State<BitcoinPaymentWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _paymentInfo;
  Timer? _checkPaymentTimer;
  String? _paymentStatus;
  String? _statusMessage;
  double? _convertedBtcAmount;
  String? _formattedAmount;
  bool _shouldCloseDialog = false;

  @override
  void initState() {
    super.initState();
    _convertAmount();
  }

  @override
  void dispose() {
    _checkPaymentTimer?.cancel();
    super.dispose();
  }

  Future<void> _convertAmount() async {
    try {
      final btcAmount = await BitcoinConversionService.usdToBitcoin(widget.amount);
      final formatted = await BitcoinConversionService.getFormattedAmount(widget.amount);
      
      setState(() {
        _convertedBtcAmount = btcAmount;
        _formattedAmount = formatted;
      });
      
      _createBitcoinPayment();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to convert amount: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createBitcoinPayment() async {
    print('🔄 Creating Bitcoin payment...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Use the converted BTC amount if available, otherwise use USD amount
      final amountToSend = _convertedBtcAmount ?? widget.amount;

      print('💰 Sending payment request: ${amountToSend} BTC (${widget.amount} USD)');

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/billing/bitcoin/create-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'planId': widget.planId,
          'amount': amountToSend,
          'usdAmount': widget.amount, // Include original USD amount for reference
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Payment created successfully: ${responseData['paymentId']}');
        
        setState(() {
          _paymentInfo = responseData;
          _isLoading = false;
        });
        
        // Start checking for payment confirmation
        _startPaymentCheck();
      } else {
        final errorBody = response.body;
        print('❌ Payment creation failed: $errorBody');
        throw Exception('Failed to create Bitcoin payment: $errorBody');
      }
    } catch (e) {
      print('💥 Payment creation error: $e');
      setState(() {
        _errorMessage = 'Failed to create payment: $e';
        _isLoading = false;
      });
      
      // Don't automatically call onError here - let user retry
      // Only call onError for unrecoverable errors
      print('🔄 Error handled, dialog will stay open for retry');
    }
  }

  void _startPaymentCheck() {
    // Check immediately
    _checkPaymentStatus();
    
    // Then check every 30 seconds
    _checkPaymentTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_paymentInfo == null) return;

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      print('🔍 Checking payment status for: ${_paymentInfo!['paymentId']}');

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/billing/bitcoin/payment-status/${_paymentInfo!['paymentId']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        print('📊 Payment status: ${status['status']} - ${status['message']}');
        
        setState(() {
          _paymentStatus = status['status'];
          _statusMessage = status['message'];
        });
        
        if (status['status'] == 'confirmed') {
          print('✅ Payment confirmed, closing dialog');
          _checkPaymentTimer?.cancel();
          
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Payment confirmed! Your subscription is now active.'),
              backgroundColor: AppColors.accentGreen,
              duration: Duration(seconds: 5),
            ),
          );
        } else if (status['status'] == 'not_found') {
          print('❌ Payment not found, showing error but keeping dialog open');
          _checkPaymentTimer?.cancel();
          
          // Don't automatically close dialog for not_found status
          // Let user see the error and retry if needed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Payment not found or expired. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        print('❌ Payment status check failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Error checking payment status: $e');
    }
  }

  Future<void> _retryPayment() async {
    print('🔄 Retrying Bitcoin payment...');
    // Reset state and try again
    setState(() {
      _errorMessage = null;
      _paymentInfo = null;
      _paymentStatus = null;
      _statusMessage = null;
      _isLoading = true;
      _shouldCloseDialog = false;
    });
    
    // Cancel any existing timer
    _checkPaymentTimer?.cancel();
    
    // Try to convert amount and create payment again
    await _convertAmount();
  }

  void _safeCloseDialog() {
    print('🚪 Safely closing Bitcoin payment dialog');
    _shouldCloseDialog = true;
    if (widget.onError != null) {
      widget.onError!();
    }
  }

  Future<void> _openBitcoinWallet() async {
    if (_paymentInfo == null) return;

    final bitcoinAddress = _paymentInfo!['address'];
    final amountToSend = _convertedBtcAmount ?? widget.amount;
    final bitcoinUri = 'bitcoin:$bitcoinAddress?amount=$amountToSend';
    
    try {
      if (await canLaunchUrl(Uri.parse(bitcoinUri))) {
        await launchUrl(Uri.parse(bitcoinUri));
      } else {
        // Fallback: copy address to clipboard
        await Clipboard.setData(ClipboardData(text: bitcoinAddress));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitcoin address copied to clipboard'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('Error opening Bitcoin wallet: $e');
    }
  }

  Color _getStatusColor() {
    switch (_paymentStatus) {
      case 'confirmed':
        return AppColors.accentGreen;
      case 'pending':
        return Colors.orange;
      case 'not_found':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_paymentStatus) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'not_found':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getStatusTitle() {
    switch (_paymentStatus) {
      case 'confirmed':
        return 'Payment Confirmed';
      case 'pending':
        return 'Payment Pending';
      case 'not_found':
        return 'Payment Not Found';
      default:
        return 'Payment Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: This dialog should NEVER auto-close on errors
    // Only close when user explicitly cancels or payment succeeds
    print('🎨 Building Bitcoin payment widget - shouldCloseDialog: $_shouldCloseDialog');
    
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 16),
            ThemedText(
              'Payment Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ThemedText(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _retryPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _safeCloseDialog,
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_paymentInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_bitcoin, color: Colors.orange),
              const SizedBox(width: 8),
              ThemedText(
                'Pay with Bitcoin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Amount display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ThemedText(
                  'Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                ThemedText(
                  '${_formattedAmount ?? widget.amount} USD',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment status indicator
          if (_paymentStatus != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor()),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ThemedText(
                          _getStatusTitle(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                        ),
                        if (_statusMessage != null) ...[
                          const SizedBox(height: 4),
                          ThemedText(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // QR Code
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 280,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.hardEdge,
                child: QrImageView(
                  data: _paymentInfo!['address'],
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bitcoin address
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText(
                  'Bitcoin Address:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _paymentInfo!['address'],
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openBitcoinWallet,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Wallet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _paymentInfo!['address']));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address copied to clipboard'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Address'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    ThemedText(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ThemedText(
                  '1. Scan the QR code or copy the Bitcoin address\n'
                  '2. Send exactly ${_formattedAmount ?? '${widget.amount} USD'} to the address\n'
                  '3. Wait for confirmation (usually 10-30 minutes)\n'
                  '4. Your subscription will be activated automatically',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 