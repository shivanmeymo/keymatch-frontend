# 🔧 Complete Guide: Fixing Google Sign-In ApiException: 10

## Problem
You're getting `PlatformException` with `ApiException: 10` when trying to sign in with Google. This is a `DEVELOPER_ERROR` that means your OAuth configuration doesn't match your app.

## Your SHA Fingerprints
```
SHA-1:  20:87:5A:D2:2F:45:0C:BB:6D:85:D6:61:C6:B0:EE:19:BE:91:B4:EE
SHA-256: 33:C4:F6:C0:60:5F:76:89:B0:B2:A5:AB:0D:4C:15:74:3C:EF:EE:E4:01:2F:A6:34:9F:1B:DB:A4:7A:24:BF:57
```

---

## STEP 1: Configure Firebase Project

### 1.1 Go to Firebase Console
Open this link in your browser:
```
https://console.firebase.google.com/project/keymatch-15954/settings/general/
```

### 1.2 Find Your Android App
- Scroll down to "Your apps" section
- Click on the Android icon (🤖) with package name `com.keymatch.app`
- OR click directly: https://console.firebase.google.com/project/keymatch-15954/settings/general/android:com.keymatch.app

### 1.3 Add SHA Fingerprints
Scroll down to the section "SHA certificate fingerprints"

**Current fingerprints you should see:**
- `d9a11f8e1b3e6301fd698b8a9ac847ce36a21fec` (release keystore)
- `20875ad22f450cbb6d85d661c6b0ee19be91b4ee` (debug keystore)

**ADD THESE TWO NEW FINGERPRINTS:**

1. Click "+ Add fingerprint"
2. Paste: `33:C4:F6:C0:60:5F:76:89:B0:B2:A5:AB:0D:4C:15:74:3C:EF:EE:E4:01:2F:A6:34:9F:1B:DB:A4:7A:24:BF:57`
   - This is your debug SHA-256
3. Click "+ Add fingerprint" again
4. Get release SHA-256:
   ```bash
   cd /home/klas/Kod/key-match-project/keymatch-frontend/android
   keytool -list -v -keystore play-store-keystore.jks -storepass keymatch123 2>&1 | grep "SHA256"
   ```
5. Paste the release SHA-256 fingerprint
6. Click "Save" at the bottom

### 1.4 Download Updated google-services.json
After adding fingerprints:
1. Scroll back up to the top of the same page
2. Click "Download google-services.json" button
3. Save the file
4. Replace the existing file:
   ```bash
   # Backup old file first
   cp /home/klas/Kod/key-match-project/keymatch-frontend/android/app/google-services.json \
      /home/klas/Kod/key-match-project/keymatch-frontend/android/app/google-services.json.backup
   
   # Copy the new downloaded file to replace it
   # (adjust the path to where you downloaded it)
   cp ~/Downloads/google-services.json \
      /home/klas/Kod/key-match-project/keymatch-frontend/android/app/google-services.json
   ```

---

## STEP 2: Configure OAuth Consent Screen (CRITICAL!)

### 2.1 Open OAuth Consent Screen
```
https://console.cloud.google.com/apis/credentials/consent?project=keymatch-15954
```

### 2.2 Check Publishing Status
At the top of the page, you'll see one of these:

#### Option A: Status is "Testing" ⚠️
If you see "Testing" status with a yellow banner:

**SOLUTION 1 (Quick - for testing only):**
1. Scroll down to "Test users" section
2. Click "+ ADD USERS" button
3. Enter your Gmail address (the one you're testing with)
4. Click "SAVE"
5. Wait 1-2 minutes for changes to propagate

**SOLUTION 2 (Recommended - for production):**
1. Click "PUBLISH APP" button at the top
2. A dialog will appear asking you to confirm
3. Click "Confirm" or "Publish"
4. Status should change to "In production" ✅

#### Option B: Status is "In production" ✅
Good! You can skip this step.

### 2.3 Verify App Information
While on this page, verify:
- **App name:** KeyMatch (or your app name)
- **User support email:** Should be filled
- **Developer contact information:** Should have an email

If any are missing:
1. Click "EDIT APP" button
2. Fill in missing information
3. Click "SAVE AND CONTINUE"

---

## STEP 3: Verify OAuth 2.0 Credentials

### 3.1 Go to Credentials Page
```
https://console.cloud.google.com/apis/credentials?project=keymatch-15954
```

### 3.2 Check OAuth 2.0 Client IDs
Look for these client IDs in the list:

**You should have at least 2 clients:**

1. **Android client** (Type: Android)
   - Name: Usually "Web client (auto created by Google Service)"
   - Client ID: Should end with `.apps.googleusercontent.com`
   - Package name: `com.keymatch.app`
   - SHA-1: Should match your fingerprints

2. **Web client** (Type: Web application)
   - Name: "Web client" or similar
   - Used by your backend for token verification

**If Android client is missing:**
1. Click "+ CREATE CREDENTIALS" at the top
2. Select "OAuth client ID"
3. Application type: "Android"
4. Name: "KeyMatch Android"
5. Package name: `com.keymatch.app`
6. SHA-1: `20:87:5A:D2:2F:45:0C:BB:6D:85:D6:61:C6:B0:EE:19:BE:91:B4:EE`
7. Click "CREATE"
8. **Important:** After creating, go back to Firebase and download google-services.json again!

---

## STEP 4: Enable Required APIs

### 4.1 Enable Google Sign-In API
```
https://console.cloud.google.com/apis/library/identitytoolkit.googleapis.com?project=keymatch-15954
```
- If you see "ENABLE" button, click it
- If you see "MANAGE" or "API enabled", you're good ✅

### 4.2 Enable Android Device Verification
```
https://console.cloud.google.com/apis/library/androidcheck.googleapis.com?project=keymatch-15954
```
- Click "ENABLE" if not already enabled

---

## STEP 5: Rebuild and Test Your App

### 5.1 Clean Build
```bash
cd /home/klas/Kod/key-match-project/keymatch-frontend
flutter clean
rm -rf android/.gradle
rm -rf android/app/build
rm -rf build
```

### 5.2 Verify google-services.json
```bash
# Check if the file has the oauth_client section
cat android/app/google-services.json | grep -A 10 "oauth_client"
```

**You should see output like:**
```json
"oauth_client": [
  {
    "client_id": "914596881459-44qh8a5pg3c5o25kt52d4qgkppen0qo0.apps.googleusercontent.com",
    "client_type": 1,
    ...
```

If `oauth_client` is empty `[]`, go back to Step 1.4 and download again!

### 5.3 Build Debug APK
```bash
flutter build apk --debug
```

### 5.4 Install on Device
```bash
# Connect your Android device via USB
# Make sure USB debugging is enabled

# Install the app
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# OR if multiple devices:
adb devices
adb -s YOUR_DEVICE_ID install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 5.5 Test Google Sign-In
1. Open the KeyMatch app
2. Clear app data first (optional but recommended):
   - Settings → Apps → KeyMatch → Storage → Clear Data
3. Click "Continue with Google"
4. Select your Google account
5. Should work! ✅

---

## STEP 6: If Still Not Working

### 6.1 Check Device Logs
```bash
# Connect device and run:
adb logcat | grep -i "google\|sign\|auth\|oauth"
```

Look for error messages that give more details.

### 6.2 Common Issues

**Issue: "unregistered_on_api_console"**
- Solution: Go back to Step 3 and verify Android OAuth client exists

**Issue: "restricted_client"**
- Solution: OAuth app is still in testing mode - go to Step 2 and publish it

**Issue: "invalid_client"**
- Solution: Package name mismatch - verify `com.keymatch.app` everywhere

**Issue: Still getting ApiException: 10**
- Clear Google Play Services cache:
  - Settings → Apps → Google Play Services → Storage → Clear Cache
  - Reboot device
  - Try again

### 6.3 Wait for Propagation
Sometimes changes take 5-10 minutes to propagate. If you just made changes:
1. Wait 10 minutes
2. Clear app data
3. Try again

---

## STEP 7: Build Release Version (After Testing)

Once debug version works, build release for Play Store:

### 7.1 Get Release SHA Fingerprints
```bash
cd /home/klas/Kod/key-match-project/keymatch-frontend/android
keytool -list -v -keystore play-store-keystore.jks -storepass keymatch123 2>&1 | grep -E "SHA1|SHA256"
```

### 7.2 Add Release Fingerprints to Firebase
- Go back to Firebase Console (Step 1.1)
- Add the release SHA-1 and SHA-256
- Download google-services.json again
- Replace the file

### 7.3 Build Release
```bash
cd /home/klas/Kod/key-match-project/keymatch-frontend
flutter build appbundle --release
```

---

## Quick Checklist ✅

Before rebuilding, verify ALL of these:

- [ ] SHA-1 fingerprint added to Firebase
- [ ] SHA-256 fingerprint added to Firebase
- [ ] OAuth consent screen published OR test user added
- [ ] Android OAuth client exists in credentials
- [ ] google-services.json downloaded and replaced
- [ ] google-services.json has non-empty oauth_client array
- [ ] App cleaned and rebuilt
- [ ] Device Google Play Services cache cleared
- [ ] Waited 5-10 minutes after making changes

---

## Need Help?

If you're still stuck, provide:
1. Screenshot of Firebase SHA fingerprints section
2. Screenshot of OAuth consent screen status
3. Output of: `cat android/app/google-services.json | grep -A 20 "oauth_client"`
4. Full error from: `adb logcat | grep -i google`

Good luck! 🚀

