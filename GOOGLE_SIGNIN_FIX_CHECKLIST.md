# ✅ Google Sign-In ApiException: 10 Fix Checklist

**Error:** `ApiException: 10` (Developer Error)  
**Cause:** OAuth configuration mismatch between app and Google Cloud Console

---

## Pre-Flight Check

Your **google-services.json** has been updated with correct SHA fingerprints:
- ✅ Debug SHA-1: `20875ad22f450cbb6d85d661c6b0ee19be91b4ee`
- ✅ Release SHA-1: `d9a11f8e1b3e6301fd698b8a9ac847ce36a21fec`

---

## Step 1: Verify Google Cloud Console OAuth Client

**Link:** https://console.cloud.google.com/apis/credentials?project=keymatch-15954

### What to Check:

1. Look for **"OAuth 2.0 Client IDs"** section
2. Find the Android client with package `com.keymatch.app`
3. Click on it to view details
4. Verify it has **BOTH** SHA-1 fingerprints:
   - `20875ad22f450cbb6d85d661c6b0ee19be91b4ee`
   - `d9a11f8e1b3e6301fd698b8a9ac847ce36a21fec`

### If Missing or Wrong:

Either:
- **Edit** the existing Android client to add missing SHA-1s, OR
- **Create** a new Android OAuth client:

```
+ CREATE CREDENTIALS → OAuth client ID
  - Application type: Android
  - Name: KeyMatch Android
  - Package name: com.keymatch.app
  - SHA-1 fingerprint: 20875ad22f450cbb6d85d661c6b0ee19be91b4ee
  → CREATE
```

Repeat for release SHA if needed.

**After making changes:**
- Wait 5-10 minutes for propagation
- Download updated google-services.json from Firebase Console

---

## Step 2: Configure OAuth Consent Screen

**Link:** https://console.cloud.google.com/apis/credentials/consent?project=keymatch-15954

### Check Publishing Status:

**If "Testing" 🟡:**

Choose ONE option:

**Option A - Add Test User (Quick):**
1. Scroll to "Test users"
2. Click "+ ADD USERS"
3. Enter your Gmail address (the one you test with)
4. Click "SAVE"
5. Wait 2-3 minutes

**Option B - Publish App (Recommended):**
1. Click "PUBLISH APP" button
2. Confirm the dialog
3. Status changes to "In production" ✅

**If "In production" ✅:**
- You're good! Proceed to Step 3.

---

## Step 3: Clean Build & Install

### On Your Computer:

```bash
cd /home/klas/Kod/key-match-project/keymatch-frontend

# The app has already been cleaned and rebuilt
# Just connect your Android device and run:
./test-google-signin.sh
```

This script will:
1. ✅ Check for connected device
2. ✅ Uninstall old app version
3. ✅ Install fresh build
4. ✅ Monitor logs for errors
5. ⚠️  Remind you to clear Google Play Services cache

---

## Step 4: Clear Google Play Services Cache (On Device)

**This is CRITICAL - OAuth changes won't work without this!**

On your Android device:
1. Settings → Apps
2. Find "Google Play Services"
3. Tap "Storage" or "Storage & cache"
4. Tap "Clear Cache" (NOT Clear Data)
5. Optional: Restart your device

---

## Step 5: Test Google Sign-In

1. Open KeyMatch app
2. Tap "Continue with Google"
3. Select your Google account
4. Should work! ✅

### Watch the Logs:

The test script automatically monitors logs. You should see:
- `Google Sign-In successful for: your@email.com`
- `ID Token: Present`
- `Status code: 200`

### If Still Getting ApiException: 10

Check the exact error in logs:

**Error: `unregistered_on_api_console`**
- → Android OAuth client doesn't exist in Step 1
- → Create it with correct package name and SHA-1

**Error: `restricted_client`**
- → OAuth app is in Testing mode without your test user
- → Complete Step 2

**Error: `invalid_client`**
- → Package name mismatch
- → Verify `com.keymatch.app` everywhere

**Still not working:**
- Clear Google Play Services **data** (not just cache)
- Reboot device
- Wait 10 minutes for Google Cloud changes to propagate
- Try with different Google account

---

## Step 6: Verify Backend Integration

Once Google Sign-In succeeds on the frontend, verify backend:

1. Check that `idToken` is sent to backend
2. Backend should verify token and create/login user
3. Backend endpoint: `POST /auth/google-login`

Check backend logs at: `192.168.1.7` [[memory:3876631]]

---

## Quick Command Reference

```bash
# Get debug SHA fingerprints
keytool -list -v -keystore ~/.android/debug.keystore \
  -storepass android -alias androiddebugkey 2>&1 | grep "SHA1\|SHA256"

# Get release SHA fingerprints  
keytool -list -v -keystore android/play-store-keystore.jks \
  -storepass keymatch123 2>&1 | grep "SHA1\|SHA256"

# Check connected devices
adb devices

# Clear app data
adb shell pm clear com.keymatch.app

# Monitor logs
adb logcat | grep -i "google\|sign\|auth"
```

---

## Summary Checklist

Before testing, verify ALL of these:

- [ ] Google Cloud Console has Android OAuth client
- [ ] Android OAuth client has correct package: `com.keymatch.app`
- [ ] Android OAuth client has debug SHA-1: `20875ad22f450cbb6d85d661c6b0ee19be91b4ee`
- [ ] OAuth consent screen is either Published OR has test user added
- [ ] google-services.json has been updated (✅ done)
- [ ] App has been rebuilt with new config (✅ done)
- [ ] Old app version uninstalled from device
- [ ] Google Play Services cache cleared on device
- [ ] Waited 5-10 minutes after making Google Cloud changes
- [ ] Device has internet connection
- [ ] Testing with correct Google account (if in Testing mode)

---

## Still Having Issues?

Provide these details:

1. Screenshot of Google Cloud OAuth clients list
2. OAuth consent screen status (Testing/Production)
3. Full error from logs: `adb logcat | grep GoogleSignIn`
4. Output of: `cat android/app/google-services.json | grep "oauth_client" -A 20`

Good luck! 🚀

