@echo off
echo Building LinkSan with maximum size optimization...

cd /d "%~dp0"

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building APK with aggressive size optimization...
flutter build apk --release ^
  --obfuscate ^
  --split-debug-info=build/app/outputs/symbols ^
  --tree-shake-icons ^
  --split-per-abi ^
  --target-platform android-arm,android-arm64 ^
  --android-skip-build-dependency-validation

echo Build completed!
echo Checking APK size...
dir build\app\outputs\flutter-apk\

echo.
echo Size optimization complete!
echo APK should now be significantly smaller.
