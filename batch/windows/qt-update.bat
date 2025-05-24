@echo off
echo ===================================================
echo Qt Update Script for Player by HEIMLICH
echo ===================================================

:: Navigate to project root
cd ..\..

echo Checking current Qt installation...

:: Check if Qt is installed
if not exist "C:\Qt" (
    echo [ERROR] Qt not found in C:\Qt
    echo Please install Qt from https://www.qt.io/download
    pause
    exit /b 1
)

:: List Qt versions
echo Available Qt versions:
dir "C:\Qt" /AD /B | findstr /R "^[0-9]\.[0-9]"

echo.
echo Current CMAKE path settings:
type CMakeLists.txt | findstr "CMAKE_PREFIX_PATH"

echo.
echo ===================================================
echo Qt Environment Information:
echo ===================================================

:: Check if qmake is in PATH
where qmake >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] qmake found in PATH
    qmake -v
) else (
    echo [WARNING] qmake not found in PATH
    echo You may need to add Qt bin directory to your PATH
)

:: Check windeployqt
where windeployqt >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] windeployqt found in PATH
) else (
    echo [WARNING] windeployqt not found in PATH
)

:: Check cmake
where cmake >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] cmake found in PATH
    cmake --version
) else (
    echo [WARNING] cmake not found in PATH
)

echo.
echo ===================================================
echo MPV Library Status:
echo ===================================================

if exist "external\libs\windows\bin\libmpv-2.dll" (
    echo [SUCCESS] MPV library found in external\libs\windows\bin\
    for %%A in ("external\libs\windows\bin\libmpv-2.dll") do echo Size: %%~zA bytes
) else (
    echo [WARNING] MPV library not found
    echo Run setup-mpv.bat first to download MPV libraries
)

echo.
echo ===================================================
echo Build Dependencies Check:
echo ===================================================

:: Check MinGW
if exist "C:\Qt\Tools\mingw1310_64\bin\gcc.exe" (
    echo [SUCCESS] MinGW found at C:\Qt\Tools\mingw1310_64\
) else if exist "C:\Qt\6.9.0\mingw_64\bin\gcc.exe" (
    echo [SUCCESS] MinGW found at C:\Qt\6.9.0\mingw_64\
) else (
    echo [WARNING] MinGW not found in expected locations
)

:: Check for common Qt modules
echo.
echo Checking Qt modules...
if exist "C:\Qt\6.9.0\mingw_64\lib\cmake\Qt6" (
    echo [SUCCESS] Qt6 CMake files found
) else (
    echo [WARNING] Qt6 CMake files not found
)

if exist "C:\Qt\6.9.0\mingw_64\qml" (
    echo [SUCCESS] Qt QML modules found
) else (
    echo [WARNING] Qt QML modules not found
)

echo.
echo ===================================================
echo Recommendations:
echo ===================================================

echo 1. Ensure Qt 6.9.0 is installed with MinGW 64-bit
echo 2. Make sure these Qt components are installed:
echo    - Qt Quick/QML
echo    - Qt Multimedia
echo    - MinGW 64-bit compiler
echo 3. Add Qt bin directory to PATH if not already done
echo 4. Run setup-mpv.bat if MPV library is missing

echo.
echo ===================================================
echo PATH Environment Variable:
echo ===================================================
echo %PATH%

echo.
echo Script completed!
cd batch\windows
pause 