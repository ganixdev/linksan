@echo off
echo ===========================================
echo LinkSan - Phase 3B: Enhanced Tree Shaking
echo ===========================================
echo.

cd /d "%~dp0"

echo [1/6] Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo Error: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo [2/6] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo [3/6] Building APK with enhanced tree shaking...
flutter build apk --release --tree-shake-icons --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
if %errorlevel% neq 0 (
    echo Error: Flutter build failed
    pause
    exit /b 1
)

echo.
echo [4/6] Building AAB with enhanced tree shaking...
flutter build appbundle --release --tree-shake-icons --obfuscate --split-debug-info=build/app/outputs/symbols
if %errorlevel% neq 0 (
    echo Error: Flutter appbundle build failed
    pause
    exit /b 1
)

echo.
echo [5/6] Analyzing APK size...
echo.
dir build\app\outputs\flutter-apk\*.apk
echo.
for %%f in (build\app\outputs\flutter-apk\*.apk) do (
    echo APK Size: %%~nxf - %%~zf bytes (%%~zf MB)
)

echo.
echo [6/6] Analyzing AAB size...
echo.
dir build\app\outputs\bundle\release\*.aab
echo.
for %%f in (build\app\outputs\bundle\release\*.aab) do (
    echo AAB Size: %%~nxf - %%~zf bytes (%%~zf MB)
)

echo.
echo ===========================================
echo Phase 3B Complete!
echo ===========================================
echo.
echo Enhanced Tree Shaking Optimizations Applied:
echo - Aggressive ProGuard rules (15 optimization passes)
echo - Enhanced ABI filtering (armeabi-v7a, arm64-v8a, x86_64)
echo - Tree shake icons enabled
echo - Code obfuscation enabled
echo - Debug symbols separated
echo - Resource shrinking enabled
echo.
echo Next: Phase 3C - Resource Optimization
echo.
pause
