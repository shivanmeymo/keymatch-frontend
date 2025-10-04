#!/bin/bash

# Simple wrapper script to build and upload APK
# Run this from the dating_app directory

echo "🚀 KeyMatch APK Builder"
echo "======================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found!"
    echo "Please run this script from the dating_app directory."
    exit 1
fi

# Run the main build script
./scripts/build-and-upload-apk.sh

echo ""
echo "✅ Done! Check the output above for results." 