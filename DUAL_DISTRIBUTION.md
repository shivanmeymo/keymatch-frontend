# KeyMatch Dual Distribution Setup

This document explains how KeyMatch is configured for dual distribution through Google Play Store and F-Droid.

## 🏗️ Build Flavors

The app uses two build flavors to support different distribution channels:

### 1. Play Store Flavor (`playstore`)
- **Payment Method**: Google Play Billing only
- **Distribution**: Google Play Store
- **Features**: 
  - Google Play Billing integration
  - Play Store compliance
  - Standard Android app experience

### 2. F-Droid Flavor (`fdroid`)
- **Payment Methods**: Stripe + Bitcoin
- **Distribution**: F-Droid repository
- **Features**:
  - Stripe payment processing
  - Bitcoin payment support
  - Open-source friendly

## 📱 Build Commands

### Build All Flavors
```bash
./scripts/build-flavors.sh all
```

### Build Specific Flavor
```bash
# Play Store flavor
./scripts/build-flavors.sh playstore

# F-Droid flavor
./scripts/build-flavors.sh fdroid
```

### Debug Builds
```bash
# Debug versions for testing
./scripts/build-flavors.sh debug
```

### Install on Device
```bash
# Install Play Store version
./scripts/build-flavors.sh install-playstore

# Install F-Droid version
./scripts/build-flavors.sh install-fdroid
```

## 🔧 Technical Implementation

### Flavor Detection
The app detects the current flavor using `FlavorHelper`:

```dart
// Check current flavor
final flavor = await FlavorHelper.getCurrentFlavor();

// Check if Play Store
if (await FlavorHelper.isPlayStore()) {
  // Show Google Play Billing
}

// Check if F-Droid
if (await FlavorHelper.isFDroid()) {
  // Show Stripe/Bitcoin options
}
```

### Payment Service
The `PaymentService` provides conditional payment screens:

```dart
// Get appropriate payment screen for current flavor
final paymentScreen = await PaymentService.getPaymentScreen(
  productId: 'premium',
  productName: 'Premium Plan',
  price: 9.99,
  onSuccess: () => print('Payment successful'),
  onCancel: () => print('Payment cancelled'),
);
```

### Available Payment Methods
```dart
// Get available methods for current flavor
final methods = await PaymentService.getAvailablePaymentMethods();

// Check if specific method is available
final hasStripe = await PaymentService.isPaymentMethodAvailable(PaymentMethod.stripe);
```

## 🎨 UI Differences

### Play Store Version
- Green color scheme
- Google Play Billing UI
- "Pay with Google Play" button
- Play Store branding

### F-Droid Version
- Blue color scheme
- Payment method selection (Stripe/Bitcoin)
- "Pay with Card" or "Pay with Bitcoin" buttons
- F-Droid branding

## 📦 Dependencies

### Play Store Flavor
- `in_app_purchase: ^3.1.13` - Google Play Billing
- `in_app_purchase_storekit: ^0.4.0` - iOS StoreKit

### F-Droid Flavor
- `flutter_stripe: ^10.2.0` - Stripe payments
- `qr_flutter: ^4.1.0` - Bitcoin QR codes
- `url_launcher: ^6.2.4` - Bitcoin wallet integration

## 🚀 Distribution

### Google Play Store
1. Build Play Store flavor: `./scripts/build-flavors.sh playstore`
2. Upload APK to Google Play Console
3. Configure in-app products in Play Console
4. Submit for review

### F-Droid
1. Build F-Droid flavor: `./scripts/build-flavors.sh fdroid`
2. Upload APK to F-Droid repository
3. Configure metadata in F-Droid
4. Submit for inclusion

## 🔒 Security Considerations

### Play Store
- Uses Google Play Billing for all transactions
- Follows Play Store policies
- Secure payment processing through Google

### F-Droid
- Stripe handles payment security
- Bitcoin payments are peer-to-peer
- No Google Play dependencies

## 🧪 Testing

### Test Both Flavors
```bash
# Test Play Store version
flutter test --flavor playstore

# Test F-Droid version
flutter test --flavor fdroid
```

### Manual Testing
1. Install both flavors on device
2. Navigate to subscription screen
3. Verify correct payment options appear
4. Test payment flows (mock payments)

## 📋 Release Checklist

### Play Store Release
- [ ] Build Play Store flavor
- [ ] Test Google Play Billing integration
- [ ] Update Play Console metadata
- [ ] Submit for review

### F-Droid Release
- [ ] Build F-Droid flavor
- [ ] Test Stripe and Bitcoin payments
- [ ] Update F-Droid metadata
- [ ] Submit for inclusion

### Both Channels
- [ ] Update version numbers
- [ ] Test on multiple devices
- [ ] Verify payment flows
- [ ] Check app functionality

## 🔄 Version Management

Both flavors share the same version number but have different application IDs:

- **Play Store**: `com.keymatch.app.playstore`
- **F-Droid**: `com.keymatch.app.fdroid`

This allows both versions to be installed simultaneously for testing.

## 📞 Support

For issues with:
- **Play Store version**: Check Google Play Console
- **F-Droid version**: Check F-Droid repository
- **Build issues**: Check build logs and dependencies 