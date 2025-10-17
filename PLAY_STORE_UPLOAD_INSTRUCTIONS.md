# Play Store Upload Instructions - v134.8.0

## ✅ Build Complete - Ready for Upload!

**Built:** October 11, 2025  
**Version:** 134.8.0 (Build 190)  
**Size:** 59.4MB  
**Changes:** Firebase Cloud Messaging integration

---

## 📦 App Bundle Location

```
/home/klas/Kod/key-match-project/keymatch-frontend/build/app/outputs/bundle/release/app-release.aab
```

---

## 🚀 Upload Steps

### 1. Go to Play Console
- Visit: https://play.google.com/console/
- Select **KeyMatch** app

### 2. Create New Release
- Go to: **Production** → **Create new release**
- Or: **Production** → **Releases** → **Create new release**

### 3. Upload App Bundle
- Click **Upload**
- Select: `app-release.aab` (from path above)
- Wait for upload to complete
- Play Console will process the bundle

### 4. Release Notes
Copy and paste these release notes:

```
Version 134.8.0 - Firebase Cloud Messaging Update

New Features:
• Improved notification system with Firebase Cloud Messaging
• Notifications now work even when app is closed
• Better battery efficiency for push notifications
• More reliable message delivery
• Enhanced notification reliability

Technical Improvements:
• Integrated Firebase Admin SDK for backend
• Optimized notification delivery system
• Improved offline message queuing
```

### 5. Review and Roll Out

**Option A: Full Rollout**
- Review changes
- Click **Review release**
- Click **Start rollout to Production**
- Confirm rollout

**Option B: Staged Rollout (Recommended)**
- Review changes
- Click **Review release**  
- Click **Start rollout to Production**
- Choose percentage: **20%** (safer)
- Monitor for 24-48 hours
- Increase to 50%, then 100%

---

## 📊 What's New in This Version

### Backend Changes (Already Deployed ✅):
- Firebase Admin SDK integrated
- FCM notification service created
- New API endpoint: `/api/auth/update-fcm-token`
- Match notifications via FCM
- Message notifications via FCM

### Frontend Changes (This Build):
- Firebase Core & Messaging packages added
- FCM token registration on login
- Background message handlers
- Foreground message handlers
- Token refresh handling
- Android notification channel configuration

### User Benefits:
- **Better Notifications:** Work even when app is closed
- **Battery Efficient:** System-level push notifications
- **Reliable:** Messages queued when offline
- **Cross-Platform:** Same experience on all devices

---

## 🧪 Pre-Upload Checklist

- [x] Backend deployed and running
- [x] Firebase initialized successfully on backend
- [x] App bundle built successfully
- [x] Version number incremented (134.8.0/190)
- [x] Firebase packages added to frontend
- [x] google-services.json in place
- [x] Build.gradle updated with Firebase plugin
- [x] F-Droid flavor removed
- [ ] Release notes ready
- [ ] Ready to upload to Play Store

---

## 🔍 Testing Before Upload (Optional)

If you want to test first:

```bash
# Build APK for testing
flutter build apk --release

# Install on test device
adb install build/app/outputs/flutter-apk/app-release.apk

# Check logs
adb logcat | grep -i firebase
```

Look for:
- `✅ Firebase initialized successfully`
- `🔑 FCM Token: [token]`
- `✅ FCM token registered with backend`

---

## 📱 After Upload

### Monitor Play Console:
1. **Pre-launch report** (24-48 hours)
   - Check for crashes
   - Review compatibility issues

2. **Crash reports**
   - Monitor for any FCM-related crashes
   - Check Firebase initialization errors

3. **Ratings & Reviews**
   - Watch for feedback about notifications
   - Monitor battery life comments

### Check Backend:
```bash
ssh -i ~/.ssh/bahnhofKey3 ubuntu@158.174.210.28
pm2 logs keymatch-backend | grep FCM
```

Look for:
- `✅ FCM notification sent successfully`
- `✅ FCM token registered with backend`

---

## 🎯 Success Metrics

After 1-3 days, check:

### Play Console:
- [ ] No spike in crashes
- [ ] Stable or improved ratings
- [ ] No significant uninstall increase
- [ ] Pre-launch tests passed

### Backend Logs:
- [ ] FCM tokens being registered
- [ ] Notifications being sent successfully
- [ ] No FCM errors

### User Feedback:
- [ ] Positive comments about notifications
- [ ] No battery drain complaints
- [ ] Notifications arriving reliably

---

## 🔄 Rollback Plan

If issues arise:

### Play Console:
1. Halt rollout (if using staged rollout)
2. Previous version still available to users
3. Fix issues and upload new version

### Backend:
```bash
ssh -i ~/.ssh/bahnhofKey3 ubuntu@158.174.210.28
cd ~/key-match
# Remove firebase-service-account.json to disable FCM temporarily
mv firebase-service-account.json firebase-service-account.json.bak
pm2 restart keymatch-backend
```

---

## 📞 Support

- **Play Console:** https://play.google.com/console/
- **Firebase Console:** https://console.firebase.google.com/u/0/project/keymatch-15954
- **Backend Status:** `ssh ubuntu@158.174.210.28 'pm2 status'`

---

## 🎉 Ready to Upload!

All systems are ready. Follow the upload steps above to release v134.8.0 to your users!

**Expected Timeline:**
- Upload: 10 minutes
- Processing: 30-60 minutes
- Review: 1-3 days (usually 24 hours)
- **Live:** 1-3 days from now

Good luck! 🚀

