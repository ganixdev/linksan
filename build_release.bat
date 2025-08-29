@echo off
REM LinkSan Release Build Script for Windows
REM Optimized for lightweight, obfuscated releases

echo 🚀 Building LinkSan Release...

REM Clean previous builds
flutter clean

REM Get dependencies
flutter pub get

REM Build Android AAB with obfuscation
echo 📱 Building Android AAB...
flutter build appbundle ^
  --release ^
  --obfuscate ^
  --split-debug-info=build/app/outputs/symbols ^
  --target-platform android-arm,android-arm64,android-x64

REM Build Android APK with obfuscation
echo 📱 Building Android APK...
flutter build apk ^
  --release ^
  --obfuscate ^
  --split-debug-info=build/app/outputs/symbols ^
  --target-platform android-arm,android-arm64,android-x64

echo ✅ Build complete!
echo.
echo 📊 Build Outputs:
echo   Android AAB: build\app\outputs\bundle\release\app-release.aab
echo   Android APK: build\app\outputs\apk\release\app-release.apk
echo.
echo 🔒 Security Features:
echo   ✅ Code obfuscation enabled
echo   ✅ Debug symbols separated
echo   ✅ 64-bit architecture support
echo   ✅ ProGuard rules applied
echo.
echo 📏 Size Optimization:
echo   ✅ Minimal dependencies
echo   ✅ Resource shrinking
echo   ✅ Compressed assets
echo   ✅ Tree shaking enabled

pause
