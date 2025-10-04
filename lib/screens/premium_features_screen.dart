import 'package:flutter/material.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/constants/colors.dart';
import 'package:key_match/screens/premium_subscription_screen.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({Key? key}) : super(key: key);

  @override
  _PremiumFeaturesScreenState createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  bool _isLoading = true;
  bool _isPremium = false;
  DateTime? _premiumExpiry;
  List<Map<String, dynamic>> _features = [];
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final isPremium = await PremiumService.isPremium();
      final expiry = await PremiumService.getPremiumExpiry();
      final features = await PremiumService.getAllFeatures();
      final plans = await PremiumService.getPremiumPlans();

      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _premiumExpiry = expiry;
          _features = features;
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading premium data: $e')),
        );
      }
    }
  }

  String _formatExpiryDate(DateTime? expiry) {
    if (expiry == null) return 'No expiry date';
    
    final now = DateTime.now();
    final difference = expiry.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours remaining';
    } else {
      return '${difference.inMinutes} minutes remaining';
    }
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    final isAvailable = feature['available'] ?? false;
    final isPremiumOnly = feature['premium_only'] ?? false;
    final name = feature['name'] ?? '';
    final description = feature['description'] ?? '';
    
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.lock;
    String statusText = 'Premium Only';
    
    if (isAvailable) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Available';
    } else if (!isPremiumOnly && feature['remaining'] != null) {
      statusColor = Colors.orange;
      statusIcon = Icons.info;
      statusText = '${feature['remaining']}/${feature['limit']} remaining';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreenLightest),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  if (feature['reset_days'] != null)
                    Text(
                      'Resets every ${feature['reset_days']} day${feature['reset_days'] == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isPopular = plan['id'] == 'yearly';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? Colors.amber : AppColors.primaryGreenLightest,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${plan['price']}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/${plan['period']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                if (plan['original_price'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '\$${plan['original_price']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            if (plan['savings'] != null) ...[
              const SizedBox(height: 4),
              Text(
                plan['savings'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Only show features section if features exist
            if (plan['features'] != null) ...[
              const Text(
                'Features:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...(plan['features'] as List).map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _purchasePlan(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? AppColors.accentGreen : AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Choose Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchasePlan(Map<String, dynamic> plan) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to purchase ${plan['name']} for \$${plan['price']}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Purchase'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // For demo purposes, simulate a successful purchase
        final days = plan['period'] == 'year' ? 365 : 30;
        await PremiumService.setPremiumStatus(true, days: days);
        
        await _loadData(); // Reload data to reflect new premium status
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium purchased successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Premium Features'),
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading premium features...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Status Card
                    if (_isPremium)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Premium Active',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _formatExpiryDate(_premiumExpiry),
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
                      ),

                    // Unlimited Likes Highlight Section
                    Container(
                      margin: const EdgeInsets.all(16),
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
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Unlimited Likes',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Like as many profiles as you want without any daily limits!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_isPremium)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PremiumSubscriptionScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Get Unlimited Likes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Features Section
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ..._features.map((feature) => _buildFeatureCard(feature)),

                    const SizedBox(height: 32),

                    // Plans Section
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Upgrade Plans',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ..._plans.map((plan) => _buildPlanCard(plan)),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
} 