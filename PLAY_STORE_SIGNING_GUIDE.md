# Google Play Store Signing Guide

## Problem
Your AAB file is being signed with the wrong certificate. Google Play Console expects:
- **Expected SHA1**: `36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB`
- **Current SHA1**: `5B:AF:EE:62:CD:47:91:DB:57:12:28:24:E6:5F:B0:DB:6E:39:43:7E`

## Solution Options

### Option 1: Find Your Original Keystore (Recommended)

The keystore with fingerprint `36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB` is the one you originally used to sign your app.

**Steps:**
1. Search your backups, cloud storage, or other locations
2. Check Google Play Console - you can download the original certificate
3. Look for any documentation that might reference this keystore
4. Check your email for any keystore files you might have sent to yourself

**Common locations to check:**
- Google Drive
- Dropbox
- OneDrive
- Local backups
- USB drives
- Email attachments

### Option 2: Contact Google Play Support

If you can't find the original keystore:

1. **Contact Google Play Developer Support**
   - Go to: https://support.google.com/googleplay/android-developer
   - Select "App signing & keys" category
   - Explain that you lost your original keystore

2. **Provide proof of ownership:**
   - Screenshots of your Google Play Console
   - Any previous APK/AAB files you have
   - Documentation of your app

3. **Request a key reset** for your app

### Option 3: Use App Signing by Google Play

If you haven't already enabled App Signing by Google Play:

1. **Go to Google Play Console**
2. **Navigate to Setup > App signing**
3. **Enable App Signing by Google Play**
4. **Upload your upload key** (the one you use to sign your AAB)
5. **Let Google handle the final signing**

### Option 4: Create a New App (Last Resort)

If you can't recover the original keystore and Google won't reset it:

1. **Create a new app** in Google Play Console
2. **Use a new package name** (e.g., `com.keymatch.app.v2`)
3. **Start fresh** with the new app

## Quick Fix Scripts

### Create New Keystore
```bash
cd key-match/dating_app
./scripts/create-play-store-keystore.sh
```

### Build AAB for Play Store
```bash
cd key-match/dating_app
./scripts/build-play-store-aab.sh
```

### Check Keystore Fingerprint
```bash
keytool -list -v -keystore android/play-store-keystore.jks -alias play-store-key -storepass keymatch123 -keypass keymatch123
```

## Manual Steps

### 1. Update key.properties
If you find your original keystore, update `android/key.properties`:
```properties
storePassword=your_password
keyPassword=your_password
keyAlias=your_alias
storeFile=path_to_your_original_keystore
```

### 2. Build AAB
```bash
flutter build appbundle --release
```

### 3. Verify Fingerprint
```bash
keytool -list -v -keystore your_keystore_file -alias your_alias -storepass your_password
```

### 4. Upload to Play Console
- Go to Google Play Console
- Navigate to your app
- Go to Production > Create new release
- Upload your AAB file

## Troubleshooting

### If you get "keystore password was incorrect"
- Try different passwords you commonly use
- Check if the keystore is corrupted
- Try opening the keystore in Android Studio

### If the fingerprint still doesn't match
- Make sure you're using the correct keystore file
- Verify the alias name is correct
- Check that the keystore file isn't corrupted

### If you can't find the original keystore
- Contact Google Play Support immediately
- Don't create a new app unless absolutely necessary
- Consider using App Signing by Google Play for future releases

## Prevention for Future

1. **Backup your keystore** in multiple secure locations
2. **Use App Signing by Google Play** to avoid this issue
3. **Document your keystore details** in a secure location
4. **Test your builds** before uploading to Play Console

## Important Notes

- **Never lose your Play Store keystore** - it's required for all future updates
- **App Signing by Google Play** is recommended for new apps
- **Contact Google Support** if you can't resolve this issue
- **Don't create multiple apps** unless absolutely necessary

## Support Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Signing by Google Play](https://support.google.com/googleplay/android-developer/answer/7384423)
- [Android App Bundle](https://developer.android.com/guide/app-bundle) 