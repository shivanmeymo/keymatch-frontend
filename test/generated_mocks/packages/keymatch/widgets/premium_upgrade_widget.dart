import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/premium_service.dart';
import '../widgets/themed_text.dart';
import '../widgets/themed_view.dart';
import '../screens/premium_subscription_screen.dart';

class PremiumUpgradeWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? featureName;
  final VoidCallback? onUpgrade;
  final bool showFeatureInfo;

  const PremiumUpgradeWidget({
    Key? key,
    this.title = 'Upgrade to Premium',
    this.message = 'Unlock unlimited likes and more features!',
    this.featureName,
    this.onUpgrade,
    this.showFeatureInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.circular(16),
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
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          ThemedText(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Message
          ThemedText(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Feature info if specified
          if (showFeatureInfo && featureName != null) ...[
            FutureBuilder<Map<String, dynamic>>(
              future: PremiumService.getFeatureUsage(featureName!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final feature = snapshot.data!;
                  if (feature['premium_only'] == true) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ThemedText(
                              '${feature['name']} - Premium Only',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (feature['remaining'] != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ThemedText(
                              '${feature['remaining']} ${feature['name']} remaining today',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Upgrade button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (onUpgrade != null) {
                  onUpgrade!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PremiumSubscriptionScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const ThemedText(
                'Upgrade Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact version for smaller spaces
class CompactPremiumWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onUpgrade;

  const CompactPremiumWidget({
    Key? key,
    this.message = 'Upgrade to Premium',
    this.onUpgrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.1),
            AppColors.primaryGreenLight.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ThemedText(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (onUpgrade != null) {
                onUpgrade!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PremiumSubscriptionScreen(),
                  ),
                );
              }
            },
            child: const ThemedText(
              'Upgrade',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 