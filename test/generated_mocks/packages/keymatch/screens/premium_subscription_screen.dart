import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/billing_service.dart';
import '../services/premium_service.dart';
import '../widgets/themed_text.dart';
import '../widgets/themed_view.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }

  Future<void> _initializeBilling() async {
    try {
      final success = await BillingService.initialize();
      if (success) {
        final plans = BillingService.getPremiumPlans();
        setState(() {
          _plans = plans;
          _selectedPlanId = plans.isNotEmpty ? plans.first['id'] : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Billing service not available');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to initialize billing');
    }
  }

  Future<void> _purchasePlan(String planId) async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await BillingService.purchaseProduct(planId);
      if (success) {
        _showSuccessSnackBar('Purchase initiated successfully');
      } else {
        _showErrorSnackBar('Failed to initiate purchase');
      }
    } catch (e) {
      _showErrorSnackBar('Error during purchase: $e');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    try {
      final success = await BillingService.restorePurchases();
      if (success) {
        _showSuccessSnackBar('Purchases restored successfully');
      } else {
        _showErrorSnackBar('Failed to restore purchases');
      }
    } catch (e) {
      _showErrorSnackBar('Error restoring purchases: $e');
    }
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
    return ThemedView(
      child: Scaffold(
        appBar: AppBar(
          title: const ThemedText(
            'Premium Subscription',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: _restorePurchases,
              child: const ThemedText(
                'Restore',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
                    
                    // Purchase button
                    _buildPurchaseButton(),
                    const SizedBox(height: 16),
                    
                    // Terms and conditions
                    _buildTermsSection(),
                  ],
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ThemedText(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._plans.map((plan) => _buildPlanCard(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlanId == plan['id'];
    final hasSavings = plan['savings'] != null;
    
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
          color: isSelected ? AppColors.surfaceLight : Colors.transparent,
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
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      if (hasSavings) ...[
                        const SizedBox(width: 8),
                        ThemedText(
                          '\$${plan['original_price']}',
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      ThemedText(
                        '/${plan['period']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
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
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.favorite, 'Unlimited Likes', 'Like as many profiles as you want'),
        _buildFeatureItem(Icons.filter_list, 'Advanced Filters', 'Filter by age, location, and more'),
        _buildFeatureItem(Icons.visibility, 'Read Receipts', 'See when your messages are read'),
        _buildFeatureItem(Icons.people, 'See Who Likes You', 'See who has liked your profile'),
        _buildFeatureItem(Icons.priority_high, 'Priority Matching', 'Get priority in the matching algorithm'),
        _buildFeatureItem(Icons.support_agent, 'Premium Support', 'Get priority customer support'),
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
            child: Icon(
              icon,
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
                  ),
                ),
                ThemedText(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    if (_selectedPlanId == null) return const SizedBox.shrink();
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing ? null : () => _purchasePlan(_selectedPlanId!),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
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
            : const ThemedText(
                'Subscribe Now',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
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
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Navigate to Terms of Service
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
                color: Colors.grey,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Privacy Policy
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