import 'package:flutter/material.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/constants/colors.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (feature['reset_days'] != null)
                    Text(
                      'Resets every ${feature['reset_days']} day${feature['reset_days'] == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
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
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: isPopular ? 4 : 2,
      child: Container(
        decoration: isPopular
            ? BoxDecoration(
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
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
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/${plan['period']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (plan['original_price'] != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '\$${plan['original_price']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
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
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _purchasePlan(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? AppColors.greenAccent : AppColors.tintColorLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Choose Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchasePlan(Map<String, dynamic> plan) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Purchase'),
          content: Text(
            'Are you sure you want to purchase ${plan['name']} for \$${plan['price']}?',
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Premium Features'),
        backgroundColor: AppColors.tintColorLight,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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

                    // Features Section
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Features',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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