# Play Store Release v217
**Build Date:** October 26, 2025  
**Version Name:** 134.10.0  
**Version Code:** 217

## Changes in This Release

### Google Authentication - FULLY FIXED ✅
- Fixed Google Sign-In SHA fingerprints configuration
- Updated Firebase with correct debug and release SHA-1/SHA-256
- Published OAuth consent screen to production
- Added all Google Client IDs to backend (debug, release, web)
- Fixed lastName validation for Google users (auto-fills if missing)
- **Google Sign-In now works end-to-end!**

### UI/UX Improvements ✅
- **Fixed Swipe Error:** Resolved Dismissible widget "dismissed widget still in tree" error
- **Edit Event Dialog:** Green background with white text for consistent theming
- **Date/Time Pickers:** Green background with white text for all pickers (birthdays, events, etc.)
- **Event Management:** Added delete button for event creators with confirmation dialog
- **Navigation:** Removed back buttons from all tabs for cleaner navigation experience
- **Material Icons:** Properly configured and loaded throughout the app
- **Leave Event:** Event creators cannot leave their own events (only delete)

### Features Added ✅
- Event creators can delete their own events (with confirmation)
- Participants can leave events (but not creators)
- Consistent green theming across all dialogs and pickers

### Bug Fixes ✅
- Fixed Dismissible widget causing crashes during swipe
- Fixed color contrast issues in event dialogs
- Fixed Leave button showing for event creators
- Fixed profile pictures not showing for premium messages in Messages tab

## Build Information
- **AAB File:** keymatch-v134.10.0+217.aab
- **Size:** 58MB
- **Build Type:** Release (signed with play-store-keystore.jks)
- **Keystore:** play-store-keystore.jks
- **Package:** com.keymatch.app

## Testing Completed
✅ Google Sign-In authentication (end-to-end)  
✅ Swipe functionality without errors  
✅ Event creation, editing, and deletion  
✅ Event leave functionality (for participants only)  
✅ Dialog theming consistency  
✅ Date/time picker theming (birthday, events)  

## Backend Changes Deployed
✅ GOOGLE_CLIENT_ID configured on production (158.174.210.28)  
✅ Updated authController.js with multi-client ID support  
✅ Fixed lastName validation for Google users  

## Upload Instructions
1. Go to Google Play Console: https://play.google.com/console
2. Navigate to KeyMatch app
3. Go to Release → Production → Create new release
4. Upload `keymatch-v134.10.0+217.aab`
5. Add release notes:

```
What's New in Version 134.10.0 (217):

✅ Google Sign-In - Now fully functional and reliable
✅ Improved event management - Edit and delete your events
✅ Better UI consistency - Green themed dialogs throughout
✅ Bug fixes - Smoother swiping experience
✅ Enhanced date/time pickers for better usability

Enjoy matching! 🎉
```

6. Review and publish!

---

**Ready for Play Store upload! 🚀**

**File Location:** `/home/klas/Kod/key-match-project/keymatch-frontend/keymatch-v134.10.0+217.aab`

