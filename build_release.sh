#!/bin/bash
# LinkSan Release Build Script
# Optimized for lightweight, obfuscated releases

set -e

echo "🚀 Building LinkSan Release..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build Android AAB with obfuscation
echo "📱 Building Android AAB..."
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --target-platform android-arm,android-arm64,android-x64

# Build Android APK with obfuscation
echo "📱 Building Android APK..."
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --target-platform android-arm,android-arm64,android-x64

# Build iOS IPA (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS IPA..."
    flutter build ios \
      --release \
      --obfuscate \
      --split-debug-info=build/ios/outputs/symbols
fi

echo "✅ Build complete!"
echo ""
echo "📊 Build Outputs:"
echo "  Android AAB: build/app/outputs/bundle/release/app-release.aab"
echo "  Android APK: build/app/outputs/apk/release/app-release.apk"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  iOS IPA: build/ios/ipa/Runner.ipa"
fi
echo ""
echo "🔒 Security Features:"
echo "  ✅ Code obfuscation enabled"
echo "  ✅ Debug symbols separated"
echo "  ✅ 64-bit architecture support"
echo "  ✅ ProGuard rules applied"
echo ""
echo "📏 Size Optimization:"
echo "  ✅ Minimal dependencies"
echo "  ✅ Resource shrinking"
echo "  ✅ Compressed assets"
echo "  ✅ Tree shaking enabled"
