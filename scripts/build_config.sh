#!/bin/bash

# Build configuration script for Modern Workout Tracker

echo "🏗️  Setting up build configuration for Modern Workout Tracker..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code (for future use with build_runner)
echo "🔧 Running code generation..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build for Android (debug)
echo "🤖 Building Android debug APK..."
flutter build apk --debug

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS app..."
    flutter build ios --debug --no-codesign
else
    echo "⚠️  Skipping iOS build (not on macOS)"
fi

echo "✅ Build configuration complete!"
echo ""
echo "📱 To run the app:"
echo "   flutter run"
echo ""
echo "🚀 To build for release:"
echo "   Android: flutter build apk --release"
echo "   iOS: flutter build ios --release"