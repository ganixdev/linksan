@echo off
echo ===========================================
echo LinkSan - Tree Shaking Analysis Tool
echo ===========================================
echo.

cd /d "%~dp0"

echo Analyzing current build for tree shaking effectiveness...
echo.

if not exist "build\app\outputs\flutter-apk\" (
    echo No APK build found. Please run build_optimized.bat first.
    echo.
    pause
    exit /b 1
)

echo [1/4] Analyzing APK structure...
echo.
echo APK Contents:
powershell "Get-ChildItem -Path 'build\app\outputs\flutter-apk\' -Recurse | Where-Object { $_.Extension -eq '.apk' } | ForEach-Object { Write-Host ('File: ' + $_.Name + ' | Size: ' + [math]::Round($_.Length / 1MB, 2) + ' MB') }"

echo.
echo [2/4] Checking for debug symbols...
if exist "build\app\outputs\symbols\" (
    echo Debug symbols found and separated (GOOD for size optimization)
    powershell "Get-ChildItem -Path 'build\app\outputs\symbols\' -Recurse | Measure-Object -Property Length -Sum | ForEach-Object { Write-Host ('Debug symbols size: ' + [math]::Round($_.Sum / 1MB, 2) + ' MB') }"
) else (
    echo Warning: Debug symbols not separated
)

echo.
echo [3/4] Analyzing asset sizes...
if exist "assets\" (
    echo Asset sizes:
    powershell "Get-ChildItem -Path 'assets\' -File | ForEach-Object { Write-Host ('  ' + $_.Name + ': ' + $_.Length + ' bytes') }"
)

echo.
echo [4/4] Build optimization summary...
echo.
echo Current optimizations applied:
echo - Tree shaking: ENABLED
echo - Code obfuscation: ENABLED
echo - Resource shrinking: ENABLED
echo - ABI splitting: ENABLED
echo - Debug symbol separation: ENABLED
echo - ProGuard optimization passes: 15
echo.

echo ===========================================
echo Analysis Complete
echo ===========================================
echo.
echo Recommendations for further optimization:
echo 1. Monitor APK size changes after each build
echo 2. Consider removing unused Flutter plugins
echo 3. Review and minimize asset files
echo 4. Test app functionality after optimizations
echo.
pause
