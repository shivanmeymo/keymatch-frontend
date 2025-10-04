import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'billing_service.dart';
import 'payment_service.dart';

enum DistributionPlatform {
  playStore,
  fdroid,
  direct,
  unknown,
}

class DistributionService {
  static DistributionPlatform? _detectedPlatform;
  static bool _isInitialized = false;

  /// Initialize the distribution service and detect the platform
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _detectedPlatform = await _detectPlatform();
      _isInitialized = true;
      print('📱 Detected distribution platform: $_detectedPlatform');
    } catch (e) {
      print('Error detecting platform: $e');
      _detectedPlatform = DistributionPlatform.unknown;
    }
  }

  /// Get the detected distribution platform
  static DistributionPlatform get platform {
    if (!_isInitialized) {
      print('⚠️ DistributionService not initialized. Call initialize() first.');
      return DistributionPlatform.unknown;
    }
    return _detectedPlatform ?? DistributionPlatform.unknown;
  }

  /// Check if the app is distributed through Google Play Store
  static bool get isPlayStore => platform == DistributionPlatform.playStore;

  /// Check if the app is distributed through F-Droid
  static bool get isFdroid => platform == DistributionPlatform.fdroid;

  /// Check if the app is distributed directly (APK download)
  static bool get isDirect => platform == DistributionPlatform.direct;

  /// Get the appropriate payment service for the current platform
  static String get recommendedPaymentMethod {
    switch (platform) {
      case DistributionPlatform.playStore:
        return 'Google Play Billing';
      case DistributionPlatform.fdroid:
        return 'Bitcoin/Stripe';
      case DistributionPlatform.direct:
        return 'Bitcoin/Stripe';
      case DistributionPlatform.unknown:
        return 'Bitcoin/Stripe (fallback)';
    }
  }

  /// Check if Google Play Billing should be used
  static Future<bool> shouldUseGooglePlayBilling() async {
    await initialize();
    
    // For F-Droid builds, never use Google Play Billing
    if (isFdroid) {
      print('📱 F-Droid detected: Using Bitcoin/Stripe payments instead of Google Play Billing');
      return false;
    }
    
    // For Play Store, check if billing is available
    if (isPlayStore) {
      try {
        final isAvailable = BillingService.isAvailable;
        print('📱 Play Store detected: Google Play Billing available: $isAvailable');
        return isAvailable;
      } catch (e) {
        print('Error checking Google Play Billing availability: $e');
        return false;
      }
    }
    
    // For other platforms, don't use Google Play Billing
    return false;
  }

  /// Get available payment methods for the current platform
  static List<PaymentMethod> getAvailablePaymentMethods() {
    switch (platform) {
      case DistributionPlatform.playStore:
        return [
          PaymentMethod.googlePlay, // Only Google Play Billing for Play Store
        ];
      case DistributionPlatform.fdroid:
      case DistributionPlatform.direct:
        return [
          PaymentMethod.bitcoin, // Primary for F-Droid
          PaymentMethod.stripe,  // Secondary for F-Droid
        ];
      case DistributionPlatform.unknown:
        return [
          PaymentMethod.bitcoin, // Primary fallback
          PaymentMethod.stripe,  // Secondary fallback
        ];
    }
  }

  /// Detect the distribution platform
  static Future<DistributionPlatform> _detectPlatform() async {
    try {
      // Method 1: Check if Google Play Services are available
      if (Platform.isAndroid) {
        final isGooglePlayAvailable = await _checkGooglePlayServices();
        if (isGooglePlayAvailable) {
          print('📱 Google Play Services detected - likely Play Store build');
          return DistributionPlatform.playStore;
        }
      }

      // Method 2: Check package installer
      final packageInfo = await PackageInfo.fromPlatform();
      final installer = await _getPackageInstaller();
      
      if (installer != null) {
        print('📱 Package installer: $installer');
        if (installer.toLowerCase().contains('com.android.vending') ||
            installer.toLowerCase().contains('google play')) {
          return DistributionPlatform.playStore;
        } else if (installer.toLowerCase().contains('fdroid') ||
                   installer.toLowerCase().contains('org.fdroid')) {
          print('📱 F-Droid installer detected');
          return DistributionPlatform.fdroid;
        }
      }

      // Method 3: Check for F-Droid specific indicators
      if (await _hasFdroidIndicators()) {
        print('📱 F-Droid indicators detected');
        return DistributionPlatform.fdroid;
      }

      // Method 4: Check if app is installed from unknown sources
      if (await _isInstalledFromUnknownSources()) {
        print('📱 App installed from unknown sources - likely direct APK');
        return DistributionPlatform.direct;
      }

      // Method 5: Check app signature for F-Droid
      if (await _isFdroidSigned()) {
        print('📱 F-Droid signature detected');
        return DistributionPlatform.fdroid;
      }

      // Default fallback - assume F-Droid if no Google Play Services
      print('📱 No specific platform detected - defaulting to F-Droid compatible');
      return DistributionPlatform.fdroid;
    } catch (e) {
      print('Error in platform detection: $e');
      return DistributionPlatform.fdroid; // Default to F-Droid for safety
    }
  }

  /// Check if Google Play Services are available
  static Future<bool> _checkGooglePlayServices() async {
    try {
      return BillingService.isAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Get the package installer information
  static Future<String?> _getPackageInstaller() async {
    try {
      // This would require platform-specific implementation
      // For now, we'll return null and rely on other detection methods
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check for F-Droid specific indicators
  static Future<bool> _hasFdroidIndicators() async {
    try {
      // Check for F-Droid specific files or configurations
      // This is a simplified check
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if app is installed from unknown sources
  static Future<bool> _isInstalledFromUnknownSources() async {
    try {
      // This would require platform-specific implementation
      // For now, we'll return false
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if the app is signed by F-Droid
  static Future<bool> _isFdroidSigned() async {
    try {
      // This would require platform-specific implementation
      // For now, we'll check if Google Play Services are NOT available
      // as a proxy for F-Droid builds
      final hasGooglePlay = await _checkGooglePlayServices();
      return !hasGooglePlay;
    } catch (e) {
      return false;
    }
  }

  /// Get platform-specific app information
  static Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': platform.name,
      'isPlayStore': isPlayStore,
      'isFdroid': isFdroid,
      'isDirect': isDirect,
      'recommendedPaymentMethod': recommendedPaymentMethod,
      'availablePaymentMethods': getAvailablePaymentMethods()
          .map((method) => method.name)
          .toList(),
    };
  }
} 