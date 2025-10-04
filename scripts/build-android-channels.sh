#!/bin/bash

# Build script for KeyMatch Android app with different channels
# Targets Android 15 (API level 35)

set -e

echo "🔧 Building KeyMatch Android app for different channels..."
echo "📱 Target: Android 15 (API level 35)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to build for a specific channel
build_channel() {
    local channel=$1
    local build_type=$2
    local output_dir="builds/$channel"
    
    echo -e "${BLUE}🏗️  Building for $channel channel...${NC}"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Clean previous build
    echo "🧹 Cleaning previous build..."
    flutter clean
    
    # Get dependencies
    echo "📦 Getting dependencies..."
    flutter pub get
    
    # Build APK
    echo "🔨 Building $build_type APK..."
    flutter build apk --$build_type --target-platform android-arm64
    
    # Copy APK to output directory
    local apk_path="build/app/outputs/flutter-apk/app-$build_type.apk"
    local output_apk="$output_dir/keymatch-$channel.apk"
    
    if [ -f "$apk_path" ]; then
        cp "$apk_path" "$output_apk"
        echo -e "${GREEN}✅ $channel build completed: $output_apk${NC}"
        
        # Show APK info
        echo "📊 APK Info:"
        ls -lh "$output_apk"
    else
        echo -e "${RED}❌ Build failed for $channel channel${NC}"
        return 1
    fi
    
    echo ""
}

# Function to build AAB for Play Store
build_aab() {
    local channel=$1
    local output_dir="builds/$channel"
    
    echo -e "${BLUE}🏗️  Building AAB for $channel channel...${NC}"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Clean previous build
    echo "🧹 Cleaning previous build..."
    flutter clean
    
    # Get dependencies
    echo "📦 Getting dependencies..."
    flutter pub get
    
    # Build AAB
    echo "🔨 Building release AAB..."
    flutter build appbundle --release --target-platform android-arm64
    
    # Copy AAB to output directory
    local aab_path="build/app/outputs/bundle/release/app-release.aab"
    local output_aab="$output_dir/keymatch-$channel.aab"
    
    if [ -f "$aab_path" ]; then
        cp "$aab_path" "$output_aab"
        echo -e "${GREEN}✅ $channel AAB completed: $output_aab${NC}"
        
        # Show AAB info
        echo "📊 AAB Info:"
        ls -lh "$output_aab"
    else
        echo -e "${RED}❌ AAB build failed for $channel channel${NC}"
        return 1
    fi
    
    echo ""
}

# Main script
echo -e "${YELLOW}🚀 KeyMatch Android Build Script${NC}"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the Flutter project root directory${NC}"
    exit 1
fi

# Create builds directory
mkdir -p builds

# Build for different channels
echo -e "${YELLOW}📱 Building APKs for different channels...${NC}"

# Internal testing (debug build)
build_channel "internal" "debug"

# Closed beta testing (release build)
build_channel "closed-beta" "release"

# Open beta testing (release build)
build_channel "open-beta" "release"

# Production AAB for Play Store
echo -e "${YELLOW}🏪 Building AAB for Play Store production...${NC}"
build_aab "production"

echo -e "${GREEN}🎉 All builds completed successfully!${NC}"
echo ""
echo -e "${BLUE}📁 Build outputs:${NC}"
echo "├── builds/internal/keymatch-internal.apk (Internal testing)"
echo "├── builds/closed-beta/keymatch-closed-beta.apk (Closed beta)"
echo "├── builds/open-beta/keymatch-open-beta.apk (Open beta)"
echo "└── builds/production/keymatch-production.aab (Play Store production)"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Test internal APK on your device"
echo "2. Upload closed-beta APK to Play Console internal testing"
echo "3. Upload open-beta APK to Play Console closed testing"
echo "4. Upload production AAB to Play Console production channel"
echo ""
echo -e "${GREEN}✅ Ready for release!${NC}" 