# KeyMatch Android Release Checklist

## Version: 134.6.0 (API Level 35 - Android 15)

### ✅ Pre-Release Updates Completed

- [x] Updated `targetSdkVersion` to 35 (Android 15)
- [x] Updated `compileSdkVersion` to 35 (Android 15)
- [x] Updated version code to 181
- [x] Updated version name to "134.6.0"
- [x] Verified build configuration
- [x] Created build script for different channels
- [x] Tested debug build successfully

### 📱 Build Channels

#### 1. Internal Testing (Debug)
- **Purpose**: Quick testing on your device
- **Build**: `./scripts/build-android-channels.sh`
- **Output**: `builds/internal/keymatch-internal.apk`
- **Testing**: Install directly on device

#### 2. Closed Beta Testing (Release)
- **Purpose**: Internal team testing via Play Console
- [ ] Upload APK to Play Console Internal Testing
- [ ] Add testers via email
- [ ] Test all core functionality
- [ ] Verify Android 15 compatibility

#### 3. Open Beta Testing (Release)
- **Purpose**: Public beta testing via Play Console
- [ ] Upload APK to Play Console Closed Testing
- [ ] Create beta testing track
- [ ] Add beta testers
- [ ] Monitor crash reports and feedback

#### 4. Production Release (AAB)
- **Purpose**: Public release on Google Play Store
- [ ] Upload AAB to Play Console Production
- [ ] Complete store listing review
- [ ] Set release notes
- [ ] Publish to production

### 🔧 Technical Requirements

#### Android 15 (API Level 35) Features
- [x] Target SDK updated to 35
- [x] Compile SDK updated to 35
- [x] Gradle configuration updated
- [x] Build tools compatibility verified

#### App Permissions
- [ ] Review and update permission requests for Android 15
- [ ] Test location permissions
- [ ] Test camera permissions
- [ ] Test storage permissions

#### Performance & Compatibility
- [ ] Test on Android 15 device/emulator
- [ ] Test on older Android versions (API 21+)
- [ ] Verify all features work correctly
- [ ] Check for any deprecation warnings

### 🧪 Testing Checklist

#### Core Features
- [ ] User registration and login
- [ ] Profile creation and editing
- [ ] Photo upload and management
- [ ] Location services
- [ ] Matching functionality
- [ ] Messaging system
- [ ] Payment processing (Stripe)
- [ ] Bitcoin payment integration
- [ ] Push notifications
- [ ] Email verification

#### UI/UX
- [ ] All screens display correctly
- [ ] Navigation works smoothly
- [ ] Dark/light theme switching
- [ ] Responsive design on different screen sizes
- [ ] Accessibility features

#### Performance
- [ ] App startup time
- [ ] Memory usage
- [ ] Battery consumption
- [ ] Network requests efficiency
- [ ] Image loading and caching

### 📋 Release Steps

#### 1. Pre-Release Testing
```bash
# Build for internal testing
./scripts/build-android-channels.sh
```

#### 2. Play Console Upload
1. Go to [Google Play Console](https://play.google.com/console)
2. Select KeyMatch app
3. Navigate to "Testing" → "Internal testing"
4. Upload APK/AAB file
5. Add testers
6. Review and publish

#### 3. Production Release
1. Complete all testing phases
2. Upload AAB to production track
3. Complete store listing review
4. Set release notes
5. Publish to production

### 🚨 Important Notes

- **Android 15**: First release targeting Android 15 (API 35)
- **Backward Compatibility**: Still supports Android 5.0+ (API 21)
- **Testing**: Thorough testing required for new API level
- **Rollback Plan**: Keep previous version ready for quick rollback if needed

### 📊 Version History

- **134.6.0** (Current): Android 15 support, bug fixes
- **134.5.9** (Previous): Android 14 support, feature updates
- **134.5.8**: Performance improvements
- **134.5.7**: UI/UX enhancements

### 🔄 Rollback Plan

If issues are discovered after release:
1. Immediately pause rollout in Play Console
2. Investigate and fix issues
3. Release hotfix version (134.6.1)
4. Resume rollout

---

**Last Updated**: $(date)
**Target Release Date**: TBD
**Status**: Ready for testing 