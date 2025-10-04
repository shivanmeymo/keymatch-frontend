import 'package:package_info_plus/package_info_plus.dart';
import '../services/payment_service.dart';

enum Flavor {
  playstore,
  fdroid,
}

class FlavorHelper {
  static Flavor? _currentFlavor;
  
  /// Get the current build flavor
  static Future<Flavor> getCurrentFlavor() async {
    print('🔍 DEBUG: getCurrentFlavor() called');
    if (_currentFlavor != null) {
      print('🔍 DEBUG: Returning cached flavor: $_currentFlavor');
      return _currentFlavor!;
    }
    
    print('🔍 DEBUG: Getting PackageInfo...');
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName.toLowerCase();
    final packageName = packageInfo.packageName.toLowerCase();
    print('🔍 DEBUG: App name from PackageInfo: ${packageInfo.appName}');
    print('🔍 DEBUG: App name lowercase: $appName');
    print('🔍 DEBUG: Package name: $packageName');
    print('🔍 DEBUG: Checking for "playstore" in: $appName');
    print('🔍 DEBUG: Contains "playstore": ${appName.contains('playstore')}');
    
    // Check if this is a Play Store build by looking for Google Play Services
    // or by checking if the package name doesn't contain 'fdroid'
    if (appName.contains('playstore') || !packageName.contains('fdroid')) {
      _currentFlavor = Flavor.playstore;
      print('🔍 DEBUG: Detected Play Store flavor');
    } else if (appName.contains('fdroid') || appName.contains('f-droid') || packageName.contains('fdroid')) {
      _currentFlavor = Flavor.fdroid;
      print('🔍 DEBUG: Detected F-Droid flavor');
    } else {
      // For now, let's assume Play Store if not explicitly F-Droid
      _currentFlavor = Flavor.playstore;
      print('🔍 DEBUG: Defaulting to Play Store flavor (not F-Droid)');
    }
    
    print('🔍 DEBUG: Final flavor: $_currentFlavor');
    return _currentFlavor!;
  }
  
  /// Check if current flavor is Play Store
  static Future<bool> isPlayStore() async {
    return await getCurrentFlavor() == Flavor.playstore;
  }
  
  /// Check if current flavor is F-Droid
  static Future<bool> isFDroid() async {
    return await getCurrentFlavor() == Flavor.fdroid;
  }
  
  /// Get available payment methods for current flavor
  static Future<List<PaymentMethod>> getAvailablePaymentMethods() async {
    final flavor = await getCurrentFlavor();
    
    switch (flavor) {
      case Flavor.playstore:
        return [PaymentMethod.googlePlay];
      case Flavor.fdroid:
        return [PaymentMethod.stripe, PaymentMethod.bitcoin];
    }
  }
  
  /// Check if a specific payment method is available
  static Future<bool> isPaymentMethodAvailable(PaymentMethod method) async {
    final availableMethods = await getAvailablePaymentMethods();
    return availableMethods.contains(method);
  }
  
  /// Force set the flavor for testing purposes
  static void setFlavorForTesting(Flavor flavor) {
    print('🔍 DEBUG: Setting flavor for testing: $flavor');
    _currentFlavor = flavor;
  }
} 