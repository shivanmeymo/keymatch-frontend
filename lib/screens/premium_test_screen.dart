import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/premium_service.dart';
import '../services/billing_service.dart';
import '../widgets/themed_text.dart';
import '../widgets/themed_view.dart';

class PremiumTestScreen extends StatefulWidget {
  const PremiumTestScreen({Key? key}) : super(key: key);

  @override
  State<PremiumTestScreen> createState() => _PremiumTestScreenState();
}

class _PremiumTestScreenState extends State<PremiumTestScreen> {
  bool _isPremium = false;
  DateTime? _expiryDate;
  Map<String, dynamic> _featureUsage = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isPremium = await PremiumService.isPremium();
      final expiry = await PremiumService.getPremiumExpiry();
      
      // Load feature usage for unlimited likes
      final likesUsage = await PremiumService.getFeatureUsage('unlimited_likes');
      final filtersUsage = await PremiumService.getFeatureUsage('advanced_filters');
      final receiptsUsage = await PremiumService.getFeatureUsage('read_receipts');

      setState(() {
        _isPremium = isPremium;
        _expiryDate = expiry;
        _featureUsage = {
          'unlimited_likes': likesUsage,
          'advanced_filters': filtersUsage,
          'read_receipts': receiptsUsage,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading premium status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setPremiumStatus(bool isPremium) async {
    await PremiumService.setPremiumStatus(isPremium);
    await _loadPremiumStatus();
  }

  Future<void> _useFeature(String featureKey) async {
    await PremiumService.useFeature(featureKey);
    await _loadPremiumStatus();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Used feature: $featureKey'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  Future<void> _clearPremiumData() async {
    await PremiumService.clearPremiumData();
    await _loadPremiumStatus();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium data cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _debugPremiumStatus() async {
    await PremiumService.debugPremiumStatus();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedView(
      child: Scaffold(
        appBar: AppBar(
          title: const ThemedText(
            'Premium Test Screen',
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
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPremiumStatus,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Status Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isPremium ? Icons.star : Icons.star_border,
                                    color: _isPremium ? AppColors.activeTabYellow : Colors.grey,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Premium Status',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Status: ${_isPremium ? "Premium" : "Free"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _isPremium ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_expiryDate != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Expires: ${_expiryDate!.toString().split(' ')[0]}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Test Controls
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Test Controls',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _setPremiumStatus(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Set Premium'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _setPremiumStatus(false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Set Free'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _clearPremiumData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Clear Data'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _debugPremiumStatus,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Debug'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Feature Testing
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Feature Testing',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Unlimited Likes
                              _buildFeatureTest(
                                'unlimited_likes',
                                'Unlimited Likes',
                                'Test like functionality',
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Advanced Filters
                              _buildFeatureTest(
                                'advanced_filters',
                                'Advanced Filters',
                                'Test filter functionality',
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Read Receipts
                              _buildFeatureTest(
                                'read_receipts',
                                'Read Receipts',
                                'Test read receipts',
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Feature Usage Display
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Feature Usage',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              for (String featureKey in _featureUsage.keys) ...[
                                _buildFeatureUsage(featureKey, _featureUsage[featureKey]),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFeatureTest(String featureKey, String name, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _useFeature(featureKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUsage(String featureKey, Map<String, dynamic> usage) {
    if (usage.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            usage['name'] ?? featureKey,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available: ${usage['available']}',
            style: TextStyle(
              fontSize: 14,
              color: usage['available'] ? Colors.green : Colors.red,
            ),
          ),
          if (usage['premium_only'] == true)
            Text(
              'Premium Only',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (usage['remaining'] != null)
            Text(
              'Remaining: ${usage['remaining']}/${usage['limit']}',
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }
} 