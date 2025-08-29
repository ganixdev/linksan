@echo off
echo ========================================
echo  LinkSan - Phase 4: Runtime Optimization
echo ========================================
echo.

cd /d "%~dp0"

echo Building optimized APK with runtime performance enhancements...
echo.

flutter build apk --release --tree-shake-icons --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

echo.
echo Build completed! Checking APK sizes...
echo.

powershell -Command "Get-ChildItem build\app\outputs\flutter-apk\*.apk | Select-Object Name, @{Name='SizeMB';Expression={[math]::Round($_.Length/1MB, 2)}} | Format-Table -AutoSize"

echo.
echo Phase 4 Runtime Optimization Features:
echo - Performance monitoring system
echo - Optimized URL manipulator with lazy initialization
echo - Memory-efficient state management
echo - Enhanced error handling and processing states
echo - Reduced unnecessary widget rebuilds
echo - Optimized string operations and memory usage
echo.

pause
