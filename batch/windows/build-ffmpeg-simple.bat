@echo off
setlocal

:: Set console to UTF-8 for proper character display
chcp 65001 >nul

echo ====================================================
echo Testing FFmpeg Build Process
echo ====================================================

:: Navigate to project root
cd ..\..

:: Step 1: Check FFmpeg dependencies
echo [STEP 1] Checking FFmpeg dependencies...

:: Check if vcpkg or system FFmpeg is available
set FFMPEG_FOUND=0

:: Try vcpkg first
if exist "C:\vcpkg\installed\x64-windows\lib\avformat.lib" (
    echo [SUCCESS] FFmpeg found via vcpkg!
    set FFMPEG_PATH=C:\vcpkg\installed\x64-windows
    set FFMPEG_FOUND=1
) else if exist "C:\vcpkg\installed\x64-mingw-dynamic\lib\libavformat.a" (
    echo [SUCCESS] FFmpeg found via vcpkg mingw!
    set FFMPEG_PATH=C:\vcpkg\installed\x64-mingw-dynamic
    set FFMPEG_FOUND=1
) else (
    echo [INFO] vcpkg FFmpeg not found, checking system installation...
    
    :: Check system installation via pkg-config
    pkg-config --exists libavformat libavcodec libavutil libswscale libswresample 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo [SUCCESS] FFmpeg found via pkg-config!
        set FFMPEG_FOUND=1
    ) else (
        echo [WARNING] FFmpeg not found via pkg-config
        echo [INFO] Build will continue - CMake will attempt to find FFmpeg
        set FFMPEG_FOUND=0
    )
)

if %FFMPEG_FOUND% EQU 1 (
    echo [INFO] FFmpeg libraries verified!
) else (
    echo [WARNING] FFmpeg not detected. Make sure FFmpeg is installed.
    echo [INFO] You can install FFmpeg via:
    echo [INFO]   - vcpkg: vcpkg install ffmpeg
    echo [INFO]   - MSYS2: pacman -S mingw-w64-x86_64-ffmpeg
    echo [INFO]   - Or download from https://www.gyan.dev/ffmpeg/builds/
)
echo.

:: Step 2: Clean up previous build files
echo [STEP 2] Cleaning up previous build files...
if exist "build" (
    rd /s /q "build" 2>nul
    timeout /t 2 /nobreak > nul
)
mkdir build

:: Step 3: Add MinGW bin directory to PATH
set PATH=C:\Qt\6.9.0\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;%PATH%

:: Add pkg-config and FFmpeg to PATH if available
if exist "C:\msys64\mingw64\bin" (
    set PATH=C:\msys64\mingw64\bin;%PATH%
    echo [INFO] Added MSYS2 to PATH for FFmpeg
)

echo [STEP 3] Running CMake for FFmpeg build...
cd build

:: Set CMAKE options for FFmpeg
set CMAKE_OPTS=-G "MinGW Makefiles" -DCMAKE_PREFIX_PATH=C:/Qt/6.9.0/mingw_64 -DCMAKE_BUILD_TYPE=Release

:: Add vcpkg toolchain if available
if exist "C:\vcpkg\scripts\buildsystems\vcpkg.cmake" (
    set CMAKE_OPTS=%CMAKE_OPTS% -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
    echo [INFO] Using vcpkg toolchain
)

echo [INFO] CMake command: cmake %CMAKE_OPTS% ..
cmake %CMAKE_OPTS% ..

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake configuration failed!
    echo [ERROR] Make sure FFmpeg libraries are installed and accessible
    cd ..
    pause
    exit /b 1
)

echo [SUCCESS] CMake configuration completed!
echo [INFO] Ready to build with: cmake --build . --config Release

cd ..\batch\windows
endlocal 