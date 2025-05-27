@echo off
echo ====================================================
echo Running Player by HEIMLICH with FFmpeg Engine
echo ====================================================

echo Checking if executable exists...
if not exist "..\..\build\Player-by-HEIMLICH.exe" (
    echo [ERROR] Player-by-HEIMLICH.exe not found in build directory!
    echo [INFO] Please run 'build-ffmpeg.bat' first to build the application.
    pause
    exit /b 1
)

echo [INFO] Checking FFmpeg DLLs...
set FFMPEG_DLL_FOUND=0

:: Check for common FFmpeg DLL names
if exist "..\..\build\avformat*.dll" (
    echo [SUCCESS] FFmpeg avformat DLL found in build directory.
    set FFMPEG_DLL_FOUND=1
) else if exist "..\..\build\libavformat*.dll" (
    echo [SUCCESS] FFmpeg libavformat DLL found in build directory.
    set FFMPEG_DLL_FOUND=1
)

if exist "..\..\build\avcodec*.dll" (
    echo [SUCCESS] FFmpeg avcodec DLL found in build directory.
    set FFMPEG_DLL_FOUND=1
) else if exist "..\..\build\libavcodec*.dll" (
    echo [SUCCESS] FFmpeg libavcodec DLL found in build directory.
    set FFMPEG_DLL_FOUND=1
)

if %FFMPEG_DLL_FOUND% EQU 0 (
    echo [WARNING] FFmpeg DLLs not found in build directory.
    echo [INFO] The application will try to use system-installed FFmpeg.
    echo [INFO] Make sure FFmpeg is installed and available in PATH.
    echo.
    echo [INFO] You can install FFmpeg via:
    echo [INFO]   - vcpkg: vcpkg install ffmpeg
    echo [INFO]   - MSYS2: pacman -S mingw-w64-x86_64-ffmpeg  
    echo [INFO]   - Or download from https://www.gyan.dev/ffmpeg/builds/
    echo.
)

echo [INFO] Starting Player by HEIMLICH with FFmpeg Engine...
echo [INFO] Video formats supported: MP4, MKV, AVI, MOV, WebM, M4V, TS, MTS, M2TS
echo.

cd ..\..\build
start Player-by-HEIMLICH.exe
cd ..\batch\windows

echo [SUCCESS] Application launched!
echo [INFO] FFmpeg Video Engine provides professional video playback capabilities.
echo. 