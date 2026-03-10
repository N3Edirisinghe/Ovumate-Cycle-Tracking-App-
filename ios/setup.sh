#!/bin/bash

# iOS Setup Script for Ovumate
# Run this script on macOS to set up iOS build environment

echo "🚀 Starting iOS Setup for Ovumate..."
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    echo "Please install Flutter first: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "📦 CocoaPods not found. Installing..."
    sudo gem install cocoapods
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to install CocoaPods"
        exit 1
    fi
    echo "✅ CocoaPods installed successfully"
else
    echo "✅ CocoaPods is already installed"
fi

# Navigate to project root
cd "$(dirname "$0")/.."

echo ""
echo "📦 Installing Flutter dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to install Flutter dependencies"
    exit 1
fi

echo ""
echo "📦 Installing iOS dependencies (CocoaPods)..."
cd ios
pod install

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to install iOS dependencies"
    echo "Try running: pod install --repo-update"
    exit 1
fi

cd ..

echo ""
echo "✅ iOS setup complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Configure signing in Xcode (Signing & Capabilities tab)"
echo "3. Select a simulator or device"
echo "4. Run: flutter run -d ios"
echo ""
echo "Or build for release:"
echo "  flutter build ios --release"
echo "  flutter build ipa --release"
echo ""













