import 'package:flutter/material.dart';
import '../services/unified_payment_service.dart';
import '../services/payment_service.dart' as pay;
import '../utils/flavor_helper.dart';
import '../constants/colors.dart';

class PlatformPaymentWidget extends StatefulWidget {
  final pay.SubscriptionTier tier;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentError;

  const PlatformPaymentWidget({
    Key? key,
    required this.tier,
    this.onPaymentSuccess,
    this.onPaymentError,
  }) : super(key: key);

  @override
  State<PlatformPaymentWidget> createState() => _PlatformPaymentWidgetState();
}

class _PlatformPaymentWidgetState extends State<PlatformPaymentWidget> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await UnifiedPaymentService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<Widget>(
          future: _buildCompleteWidget(),
          builder: (context, widgetSnapshot) {
            if (widgetSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return widgetSnapshot.data ?? const Center(child: Text('Error loading widget'));
          },
        );
      },
    );
  }

  Future<Widget> _buildCompleteWidget() async {
    final platformInfo = await _buildPlatformInfo();
    final paymentOptions = await _buildPaymentOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        platformInfo,
        const SizedBox(height: 16),
        paymentOptions,
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Future<Widget> _buildPlatformInfo() async {
    final currentFlavor = await FlavorHelper.getCurrentFlavor();
    final paymentInfo = await UnifiedPaymentService.getPaymentInfo();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Platform',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Distribution: ${currentFlavor.name}'),
            Text('Provider: ${paymentInfo['preferredProvider']}'),
          ],
        ),
      ),
    );
  }

  Future<Widget> _buildPaymentOptions() async {
    final currentFlavor = await FlavorHelper.getCurrentFlavor();
    
    if (currentFlavor == Flavor.playstore) {
      return _buildGooglePlayPayment();
    } else {
      return _buildFdroidPayment();
    }
  }

  Widget _buildGooglePlayPayment() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Google Play Billing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Purchase through Google Play Store',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _purchaseWithGooglePlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Purchase with Google Play'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFdroidPayment() {
    return Column(
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Stripe Payment',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pay with credit card or bank transfer',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _purchaseWithStripe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Pay with Stripe'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.currency_bitcoin, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Bitcoin Payment',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pay with Bitcoin cryptocurrency',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _purchaseWithBitcoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Pay with Bitcoin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseWithGooglePlay() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await UnifiedPaymentService.purchaseSubscription(widget.tier);
      
      if (result.success) {
        widget.onPaymentSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Payment failed';
        });
        widget.onPaymentError?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment error: $e';
      });
      widget.onPaymentError?.call();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseWithStripe() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await UnifiedPaymentService.purchaseSubscription(widget.tier);
      
      if (result.success) {
        widget.onPaymentSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stripe payment successful!')),
        );
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Stripe payment failed';
        });
        widget.onPaymentError?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Stripe payment error: $e';
      });
      widget.onPaymentError?.call();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseWithBitcoin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await UnifiedPaymentService.purchaseSubscription(widget.tier);
      
      if (result.success) {
        widget.onPaymentSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitcoin payment initiated!')),
        );
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Bitcoin payment failed';
        });
        widget.onPaymentError?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bitcoin payment error: $e';
      });
      widget.onPaymentError?.call();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 