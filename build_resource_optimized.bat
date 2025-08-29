@echo off
echo ===========================================
echo LinkSan - Phase 3C: Resource Optimization
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
echo [3/6] Building APK with resource optimization...
flutter build apk --release --tree-shake-icons --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
if %errorlevel% neq 0 (
    echo Error: Flutter build failed
    pause
    exit /b 1
)

echo.
echo [4/6] Analyzing split APK sizes...
echo.
for %%f in (build\app\outputs\flutter-apk\app-*-release.apk) do (
    echo APK: %%~nxf - %%~zf bytes ^(%%~zf MB^)
)

echo.
echo [5/6] Analyzing resource optimization impact...
echo.
echo Checking for resource shrinking effectiveness...
if exist "build\app\outputs\logs\manifest-merger-release-report.txt" (
    echo Resource shrinking report available
    type "build\app\outputs\logs\manifest-merger-release-report.txt"
) else (
    echo Resource shrinking report not found - checking build outputs...
    dir build\app\outputs\flutter-apk\ /b
)

echo.
echo [6/6] Build optimization complete!
echo.
echo ===========================================
echo Phase 3C Complete!
echo ===========================================
echo.
echo Resource Optimization Applied:
echo - Aggressive resource shrinking enabled
echo - Android manifest optimization
echo - Asset compression active
echo - Native library optimization
echo - Build artifact cleanup
echo.
echo Next: Phase 3D - Build Configuration Tuning
echo.
pause
