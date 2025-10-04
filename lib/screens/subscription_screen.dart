import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../utils/flavor_helper.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;
  List<PaymentMethod> _availableMethods = [];
  FlavorHelper.Flavor? _currentFlavor;

  @override
  void initState() {
    super.initState();
    _loadFlavorInfo();
  }

  Future<void> _loadFlavorInfo() async {
    final flavor = await FlavorHelper.getCurrentFlavor();
    final methods = await PaymentService.getAvailablePaymentMethods();
    
    setState(() {
      _currentFlavor = flavor;
      _availableMethods = methods;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: _getAppBarColor(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFlavorInfo(),
            const SizedBox(height: 24),
            _buildSubscriptionPlans(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentFlavor) {
      case FlavorHelper.Flavor.playstore:
        return 'Premium Subscription (Play Store)';
      case FlavorHelper.Flavor.fdroid:
        return 'Premium Subscription (F-Droid)';
      default:
        return 'Premium Subscription';
    }
  }

  Color _getAppBarColor() {
    switch (_currentFlavor) {
      case FlavorHelper.Flavor.playstore:
        return Colors.green;
      case FlavorHelper.Flavor.fdroid:
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  Widget _buildFlavorInfo() {
    return Card(
      color: _getAppBarColor().withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              _currentFlavor == FlavorHelper.Flavor.playstore
                  ? Icons.shopping_cart
                  : Icons.store,
              size: 48,
              color: _getAppBarColor(),
            ),
            const SizedBox(height: 8),
            Text(
              _currentFlavor == FlavorHelper.Flavor.playstore
                  ? 'Google Play Store Version'
                  : 'F-Droid Version',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _getAppBarColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentFlavor == FlavorHelper.Flavor.playstore
                  ? 'Payments processed through Google Play Billing'
                  : 'Payments processed through Stripe or Bitcoin',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          title: 'Premium',
          price: '\$9.99',
          period: 'month',
          features: [
            'Unlimited matches',
            'Advanced filters',
            'Priority support',
            '6 profile images',
          ],
          onTap: () => _showPaymentScreen('premium', 'Premium Plan', 9.99),
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          title: 'Enterprise',
          price: '\$29.99',
          period: 'month',
          features: [
            'All Premium features',
            'API access',
            '10 profile images',
            'Custom integrations',
          ],
          onTap: () => _showPaymentScreen('enterprise', 'Enterprise Plan', 29.99),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _getAppBarColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'per $period',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Payment Methods',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _availableMethods.map((method) {
            return Chip(
              avatar: Icon(_getPaymentMethodIcon(method)),
              label: Text(_getPaymentMethodName(method)),
              backgroundColor: _getAppBarColor().withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.googlePlay:
        return Icons.shopping_cart;
      case PaymentMethod.stripe:
        return Icons.credit_card;
      case PaymentMethod.bitcoin:
        return Icons.currency_bitcoin;
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.googlePlay:
        return 'Google Play';
      case PaymentMethod.stripe:
        return 'Credit Card';
      case PaymentMethod.bitcoin:
        return 'Bitcoin';
    }
  }

  void _showPaymentScreen(String productId, String productName, double price) {
    PaymentService.getPaymentScreen(
      productId: productId,
      productName: productName,
      price: price,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Welcome to $productName'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      },
      onCancel: () {
        Navigator.pop(context);
      },
    ).then((screen) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    });
  }
} 