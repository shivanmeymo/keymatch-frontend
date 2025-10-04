# Key-Match Build Scripts

This directory contains scripts for building and deploying the Key-Match Flutter app.

## 🚀 Unified Build Script

The main script is `build-and-deploy.sh` which replaces the old separate scripts and provides a unified interface for building and uploading your app.

### Features

- ✅ **Multi-platform support**: Android (APK/AAB) and iOS (IPA)
- ✅ **Multiple upload targets**: Google Cloud Storage and Google Drive
- ✅ **Flexible configuration**: Command-line options for all settings
- ✅ **Backward compatibility**: Old script names still work
- ✅ **Comprehensive logging**: Colored output and detailed progress
- ✅ **Error handling**: Proper error checking and reporting
- ✅ **Build summaries**: Automatic generation of build reports

### Usage

```bash
# Basic usage (builds Android APK and uploads to Google Drive)
./build-and-deploy.sh

# Build Android APK and AAB, upload to Google Cloud Storage
./build-and-deploy.sh --platform android --target all --upload gcs

# Build iOS IPA and upload to Google Drive
./build-and-deploy.sh --platform ios --target ipa --upload gdrive

# Build both platforms and upload to both destinations
./build-and-deploy.sh --platform both --target all --upload both

# Clean build with custom version
./build-and-deploy.sh --clean --version 1.2.3 --platform android --target apk
```

### Options

| Option | Short | Description | Values |
|--------|-------|-------------|---------|
| `--platform` | `-p` | Build platform | `android`, `ios`, `both` |
| `--target` | `-t` | Build target | `apk`, `aab`, `ipa`, `all` |
| `--upload` | `-u` | Upload destination | `gcs`, `gdrive`, `both` |
| `--clean` | `-c` | Clean build before building | (flag) |
| `--version` | `-v` | Override version from pubspec.yaml | (version string) |
| `--help` | `-h` | Show help message | (flag) |

### Examples

#### Android APK for Testing
```bash
./build-and-deploy.sh --platform android --target apk --upload gdrive
```

#### Android Bundle for Play Store
```bash
./build-and-deploy.sh --platform android --target aab --upload gcs
```

#### iOS IPA for Distribution
```bash
./build-and-deploy.sh --platform ios --target ipa --upload gdrive
```

#### Complete Release Build
```bash
./build-and-deploy.sh --platform both --target all --upload both --clean
```

## 🔄 Backward Compatibility

The old script names still work and automatically redirect to the unified script:

- `build-and-deploy-gcloud.sh` → Builds Android APK+AAB, uploads to Google Cloud Storage
- `build-and-upload-apk.sh` → Builds Android APK, uploads to Google Drive  
- `build-and-upload-ios.sh` → Builds iOS IPA, uploads to Google Drive

## 📁 Upload Locations

### Google Cloud Storage
- **Bucket**: `gs://fresh-oath-337920-app-releases/`
- **APKs**: `gs://fresh-oath-337920-app-releases/apks/`
- **AABs**: `gs://fresh-oath-337920-app-releases/aabs/`
- **IPAs**: `gs://fresh-oath-337920-app-releases/ipas/`

### Google Drive
- **Android**: `Key-Match/releases/android/`
- **iOS**: `Key-Match/releases/ios/`
- **Backups**: `Key-Match/releases/{platform}/backups/`

## 🔧 Prerequisites

### Required Tools
- **Flutter**: Latest stable version
- **Android SDK**: For Android builds
- **Xcode**: For iOS builds (macOS only)
- **gcloud CLI**: For Google Cloud Storage uploads
- **rclone**: For Google Drive uploads

### Setup Scripts
- `setup-rclone.sh` - Configure rclone for Google Drive access
- `generate-keystore.sh` - Generate Android signing keystore
- `setup-keystore-passwords.sh` - Set up keystore passwords

## 📊 Build Output

Each build generates:
- **Build files**: APK, AAB, or IPA with version and timestamp
- **Build summary**: `build_info_YYYYMMDD_HHMMSS.txt`
- **Upload URLs**: Direct download links for Google Cloud Storage
- **File sizes**: Human-readable file sizes

## 🛠️ Other Scripts

### Build and Deployment
- `build-and-deploy.sh` - **Main unified script**
- `build-and-deploy-gcloud.sh` - Wrapper for Google Cloud Storage
- `build-and-upload-apk.sh` - Wrapper for Android APK to Google Drive
- `build-and-upload-ios.sh` - Wrapper for iOS IPA to Google Drive

### Setup and Configuration
- `setup-rclone.sh` - Configure rclone for Google Drive
- `generate-keystore.sh` - Generate Android signing keystore
- `setup-keystore-passwords.sh` - Set up keystore passwords
- `bump-version.sh` - Increment app version

### Utilities
- `upload-apk-to-gdrive.sh` - Upload existing APK to Google Drive
- `deploy.sh` - Simple deployment script
- `activate-internal.sh` - Activate internal testing

## 🎯 Quick Start

1. **First time setup**:
   ```bash
   ./setup-rclone.sh
   ./generate-keystore.sh
   ```

2. **Build and upload Android APK**:
   ```bash
   ./build-and-deploy.sh
   ```

3. **Build everything for release**:
   ```bash
   ./build-and-deploy.sh --platform both --target all --upload both --clean
   ```

## 📝 Notes

- All builds use release configuration
- Files are automatically timestamped and versioned
- Backups are created in Google Drive
- Google Cloud Storage files are publicly accessible
- Build summaries are saved locally for reference 