import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/billing_service.dart';
import '../services/premium_service.dart';
import '../services/unified_payment_service.dart';
import '../services/bitcoin_conversion_service.dart';
import '../utils/flavor_helper.dart';
import '../widgets/themed_text.dart';
import '../widgets/themed_view.dart';
import '../widgets/stripe_payment_widget.dart';
import '../widgets/bitcoin_payment_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  bool _isLoading = true;
  bool _isPurchasing = false;
  List<Map<String, dynamic>> _plans = [];
  String? _selectedPlanId;
  PaymentProvider _selectedPaymentMethod = PaymentProvider.googlePlayBilling;
  List<PaymentProvider> _availablePaymentMethods = [];

  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }

  Future<void> _initializeBilling() async {
    print('🔍 DEBUG: _initializeBilling() called in PremiumSubscriptionScreen');
    List<Map<String, dynamic>> plans = [];
    String? errorMessage;

    try {
      print('🔍 Initializing billing service...');
      print('🔍 Current platform: ${defaultTargetPlatform}');
      
      // Initialize payment services
      print('🔍 DEBUG: About to call UnifiedPaymentService.initialize()');
      await UnifiedPaymentService.initialize();
      print('🔍 DEBUG: UnifiedPaymentService.initialize() completed');
      
      // Use FlavorHelper to detect the current flavor
      print('🔍 DEBUG: About to call FlavorHelper.getCurrentFlavor()');
      
      // For testing: Force Play Store flavor
      FlavorHelper.setFlavorForTesting(Flavor.playstore);
      
      final currentFlavor = await FlavorHelper.getCurrentFlavor();
      print('🔍 DEBUG: Detected flavor: $currentFlavor');
      
      // For Play Store builds, only use Google Play Billing
      if (currentFlavor == Flavor.playstore) {
        _availablePaymentMethods = [PaymentProvider.googlePlayBilling];
        _selectedPaymentMethod = PaymentProvider.googlePlayBilling;
        print('🔍 Play Store flavor detected: Using Google Play Billing only');
        print('🔍 DEBUG: Available payment methods: $_availablePaymentMethods');
        print('🔍 DEBUG: Selected payment method: $_selectedPaymentMethod');
      } else {
        // For F-Droid and other platforms, use Bitcoin and Stripe
        _availablePaymentMethods = await UnifiedPaymentService.getAvailableProviders();
        _selectedPaymentMethod = _availablePaymentMethods.isNotEmpty 
            ? _availablePaymentMethods.first 
            : PaymentProvider.stripe;
        print('🔍 F-Droid flavor detected: Using Bitcoin/Stripe payments');
        print('🔍 DEBUG: Available payment methods: $_availablePaymentMethods');
        print('🔍 DEBUG: Selected payment method: $_selectedPaymentMethod');
      }
      
      final success = await BillingService.initialize();
      print('🔍 Billing initialization success: $success');
      
      if (success) {
        // Billing service initialized, live prices should be available
        plans = BillingService.getPremiumPlans();
        print('🔍 Loaded ${plans.length} plans from billing service');
        for (var plan in plans) {
          print('🔍 Plan: ${plan['name']} - \$${plan['price']}/${plan['period']}');
        }
      } else {
        // Billing service not available, use fallback plans
        errorMessage = 'Billing service not available. Prices shown may be estimates.';
        print('🔍 Billing service not available, attempting to get fallback plans...');
        plans = BillingService.getPremiumPlans(); // Attempt to get plans with fallback data
        print('🔍 Using fallback plans: ${plans.length} plans');
        print('🔍 Fallback plans content: $plans');
      }
    } catch (e) {
      // Error during initialization, use fallback plans
      errorMessage = 'Failed to initialize billing. Prices shown may be estimates.';
      print('🔍 Error during initialization: $e');
      print('🔍 Attempting to get fallback plans after error...');
      plans = BillingService.getPremiumPlans(); // Attempt to get plans with fallback data
      print('🔍 Error during initialization, using fallback plans: ${plans.length} plans');
      print('🔍 Fallback plans content after error: $plans');
    } finally {
      // Ensure we always have at least fallback plans
      if (plans.isEmpty) {
        print('🔍 No plans found, creating emergency fallback plans');
        plans = [
          {
            'id': 'emergency_monthly',
            'name': 'Monthly Premium',
            'price': 9.99,
            'display_price': 9.99,
            'currency': 'USD',
            'period': 'month',
            'duration_days': 30,
          },
          {
            'id': 'emergency_yearly',
            'name': 'Yearly Premium',
            'price': 99.99,
            'display_price': 99.99,
            'currency': 'USD',
            'period': 'year',
            'duration_days': 365,
          },
        ];
        print('🔍 Created ${plans.length} emergency fallback plans');
      }
      
      setState(() {
        _plans = plans;
        _selectedPlanId = plans.isNotEmpty ? plans.first['id'] : null;
        _isLoading = false;
      });
      print('🔍 Final plans count: ${_plans.length}');
      print('🔍 Selected plan ID: $_selectedPlanId');
      
      if (errorMessage != null && plans.isNotEmpty) {
        // Show error only if we have plans to display, otherwise it's handled by empty screen
        _showErrorSnackBar(errorMessage);
      } else if (plans.isEmpty) {
        // If plans are still empty (e.g. _premiumPlans in BillingService is empty for platform)
        _showErrorSnackBar('No premium plans available for your device.');
      }
    }
  }

  Future<void> _purchasePlan(String planId) async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final selectedPlan = _plans.firstWhere((plan) => plan['id'] == planId);
      
      switch (_selectedPaymentMethod) {
        case PaymentProvider.googlePlayBilling:
          final success = await BillingService.purchaseProduct(planId);
          if (success) {
            _showSuccessSnackBar('Purchase initiated successfully');
          } else {
            _showErrorSnackBar('Failed to initiate purchase');
          }
          break;
          
        case PaymentProvider.stripe:
          await _showStripePaymentDialog(selectedPlan);
          break;
          
        case PaymentProvider.bitcoin:
          await _showBitcoinPaymentDialog(selectedPlan);
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Error during purchase: $e');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  Future<void> _showStripePaymentDialog(Map<String, dynamic> plan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ThemedText(
                      'Pay with Card',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Payment widget section
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: StripePaymentWidget(
                    planId: plan['id'],
                    planName: plan['name'],
                    amount: plan['price'].toDouble(),
                    onSuccess: () {
                      Navigator.of(context).pop();
                      _showSuccessSnackBar('Payment successful! Your subscription is now active.');
                    },
                    onError: () {
                      Navigator.of(context).pop();
                      _showErrorSnackBar('Payment failed. Please try again.');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBitcoinPaymentDialog(Map<String, dynamic> plan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ThemedText(
                      'Pay with Bitcoin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Payment widget section
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: BitcoinPaymentWidget(
                    planId: plan['id'],
                    planName: plan['name'],
                    amount: plan['price'].toDouble(),
                    onSuccess: () {
                      Navigator.of(context).pop();
                      _showSuccessSnackBar('Payment confirmed! Your subscription is now active.');
                    },
                    onError: () {
                      Navigator.of(context).pop();
                      _showErrorSnackBar('Payment failed. Please try again.');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const ThemedText(
          'Premium Subscription',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Plans section
                  _buildPlansSection(),
                  const SizedBox(height: 24),
                  
                  // Features section
                  _buildFeaturesSection(),
                  const SizedBox(height: 24),
                  
                  // Payment method selection (only show if multiple methods available)
                  if (_availablePaymentMethods.length > 1) _buildPaymentMethodSelection(),
                  
                  // Purchase button
                  _buildPurchaseButton(),
                  const SizedBox(height: 16),
                  
                  // Terms and conditions
                  _buildTermsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreenLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const ThemedText(
            'Unlock Premium Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const ThemedText(
            'Get unlimited likes, advanced filters, and more to find your perfect match!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    print('🔍 Building plans section with \\${_plans.length} plans');
    print('🔍 Plans type: \\${_plans.runtimeType}');
    print('🔍 Plans isEmpty: \\${_plans.isEmpty}');
    
    if (_plans.isNotEmpty) {
      for (int i = 0; i < _plans.length; i++) {
        final plan = _plans[i];
        print('🔍 Plan $i: ${plan['name']} - \$${plan['price']}/${plan['period']}');
        print('🔍 Plan $i features: ${plan['features']}');
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ThemedText(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (_plans.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: ThemedText(
                'No premium plans available at the moment. Please try again later.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._plans.map((plan) => _buildPlanCard(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlanId == plan['id'];
    final hasSavings = plan['savings'] != null;
    
    // Debug logging
    print('🔍 Building plan card: ${plan['name']}');
    print('🔍 Plan ID: ${plan['id']}');
    print('🔍 Plan price: ${plan['price']}');
    print('🔍 Plan period: ${plan['period']}');
    print('🔍 Plan features: ${plan['features']}');
    print('🔍 Has savings: $hasSavings');
    print('🔍 Is selected: $isSelected');
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanId = plan['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreenLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.primaryGreen,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ThemedText(
                        plan['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (hasSavings) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ThemedText(
                            plan['savings'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ThemedText(
                        '\$${plan['price']}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (hasSavings) ...[
                        const SizedBox(width: 8),
                        ThemedText(
                          '\$${plan['original_price']}',
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      ThemedText(
                        '/${plan['period']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Add features list for each plan (only if features exist)
                  if (plan['features'] != null)
                    ...(plan['features'] as List<dynamic>).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ThemedText(
                              feature.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ThemedText(
          'Premium Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.favorite, 'Unlimited Likes', 'Send unlimited likes without any daily restrictions'),
        _buildFeatureItem(Icons.chat_bubble, '100 AI Messages', 'Get 100 AI-powered conversation starters and responses per day'),
        _buildFeatureItem(Icons.message, 'Like by Sending Message', 'Automatically like profiles when you send them a message'),

      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                ThemedText(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ThemedText(
          'Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ..._availablePaymentMethods.map((method) => _buildPaymentMethodOption(method)),
      ],
    );
  }

  Widget _buildPaymentMethodOption(PaymentProvider method) {
    final isSelected = _selectedPaymentMethod == method;
    final icon = _getPaymentMethodIcon(method);
    final title = _getPaymentMethodTitle(method);
    final description = _getPaymentMethodDescription(method);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.surfaceDark : AppColors.backgroundDark,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.primaryGreen,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemedText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  ThemedText(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentProvider method) {
    switch (method) {
      case PaymentProvider.stripe:
        return Icons.credit_card;
      case PaymentProvider.bitcoin:
        return Icons.currency_bitcoin;
      case PaymentProvider.googlePlayBilling:
        return Icons.shopping_cart;
    }
  }

  String _getPaymentMethodTitle(PaymentProvider method) {
    switch (method) {
      case PaymentProvider.stripe:
        return 'Credit/Debit Card';
      case PaymentProvider.bitcoin:
        return 'Bitcoin';
      case PaymentProvider.googlePlayBilling:
        return 'Google Play Billing';
    }
  }

  String _getPaymentMethodDescription(PaymentProvider method) {
    switch (method) {
      case PaymentProvider.stripe:
        return 'Pay securely with your card';
      case PaymentProvider.bitcoin:
        return 'Pay with cryptocurrency';
      case PaymentProvider.googlePlayBilling:
        return 'Pay through Google Play Store';
    }
  }

  Widget _buildPurchaseButton() {
    if (_selectedPlanId == null) return const SizedBox.shrink();
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing ? null : () => _purchasePlan(_selectedPlanId!),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isPurchasing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : ThemedText(
                _getPurchaseButtonText(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  String _getPurchaseButtonText() {
    switch (_selectedPaymentMethod) {
      case PaymentProvider.stripe:
        return 'Pay with Card';
      case PaymentProvider.bitcoin:
        return 'Pay with Bitcoin';
      case PaymentProvider.googlePlayBilling:
        return 'Subscribe with Google Play';
    }
  }

  Widget _buildTermsSection() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        ThemedText(
          'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                const termsUrl = 'https://klas96.github.io/keymatch-policy/terms.html';
                if (await canLaunchUrl(Uri.parse(termsUrl))) {
                  await launchUrl(
                    Uri.parse(termsUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  // Fallback: show error or handle gracefully
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open Terms of Service'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const ThemedText(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const ThemedText(
              '•',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            TextButton(
              onPressed: () async {
                const privacyUrl = 'https://klas96.github.io/keymatch-policy/privacy-policy.html';
                if (await canLaunchUrl(Uri.parse(privacyUrl))) {
                  await launchUrl(
                    Uri.parse(privacyUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  // Fallback: show error or handle gracefully
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open Privacy Policy'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const ThemedText(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    BillingService.dispose();
    super.dispose();
  }
} 