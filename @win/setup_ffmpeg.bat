@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   FFmpeg ProRes Setup Script
echo ========================================

:: Color settings
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Environment variables
set "MSYS2_PATH=C:\msys64\mingw64"
set "PROJECT_ROOT=%~dp0.."
set "FFMPEG_DIR=%PROJECT_ROOT%\external\ffmpeg"

echo %BLUE%[INFO]%NC% Setting up FFmpeg for ProRes support...
echo %BLUE%[INFO]%NC% Project root: %PROJECT_ROOT%
echo %BLUE%[INFO]%NC% FFmpeg directory: %FFMPEG_DIR%

:: Check if MSYS2 is installed
if not exist "%MSYS2_PATH%\bin\ffmpeg.exe" (
    echo %RED%[ERROR]%NC% MSYS2 FFmpeg not found.
    echo %YELLOW%[INFO]%NC% Please install MSYS2 and run:
    echo   pacman -S mingw-w64-x86_64-ffmpeg
    pause
    exit /b 1
)

:: Check ProRes support
echo %BLUE%[INFO]%NC% Checking ProRes support...
"%MSYS2_PATH%\bin\ffmpeg.exe" -codecs 2>nul | findstr "prores" >nul
if errorlevel 1 (
    echo %RED%[ERROR]%NC% ProRes codec not found in FFmpeg
    pause
    exit /b 1
) else (
    echo %GREEN%[OK]%NC% ProRes codec support confirmed
)

:: Create FFmpeg directory structure
echo %BLUE%[INFO]%NC% Creating FFmpeg directory structure...
if not exist "%FFMPEG_DIR%" mkdir "%FFMPEG_DIR%"
if not exist "%FFMPEG_DIR%\include" mkdir "%FFMPEG_DIR%\include"
if not exist "%FFMPEG_DIR%\lib" mkdir "%FFMPEG_DIR%\lib"
if not exist "%FFMPEG_DIR%\bin" mkdir "%FFMPEG_DIR%\bin"

:: Copy FFmpeg headers
echo %BLUE%[INFO]%NC% Copying FFmpeg headers...
robocopy "%MSYS2_PATH%\include" "%FFMPEG_DIR%\include" libav* /E /NFL /NDL /NJH /NJS
if errorlevel 8 (
    echo %RED%[ERROR]%NC% Failed to copy FFmpeg headers
    pause
    exit /b 1
)

:: Copy FFmpeg libraries
echo %BLUE%[INFO]%NC% Copying FFmpeg libraries...
copy "%MSYS2_PATH%\lib\libav*.dll.a" "%FFMPEG_DIR%\lib\" >nul 2>&1
copy "%MSYS2_PATH%\lib\libsw*.dll.a" "%FFMPEG_DIR%\lib\" >nul 2>&1

:: Copy FFmpeg DLLs
echo %BLUE%[INFO]%NC% Copying FFmpeg DLLs...
copy "%MSYS2_PATH%\bin\av*.dll" "%FFMPEG_DIR%\bin\" >nul 2>&1
copy "%MSYS2_PATH%\bin\sw*.dll" "%FFMPEG_DIR%\bin\" >nul 2>&1

:: Verify installation
echo %BLUE%[INFO]%NC% Verifying installation...
if not exist "%FFMPEG_DIR%\include\libavformat\avformat.h" (
    echo %RED%[ERROR]%NC% FFmpeg headers not found
    pause
    exit /b 1
)

if not exist "%FFMPEG_DIR%\lib\libavformat.dll.a" (
    echo %RED%[ERROR]%NC% FFmpeg libraries not found
    pause
    exit /b 1
)

if not exist "%FFMPEG_DIR%\bin\avformat-61.dll" (
    echo %RED%[ERROR]%NC% FFmpeg DLLs not found
    pause
    exit /b 1
)

:: Display FFmpeg version and ProRes support
echo.
echo %GREEN%[SUCCESS]%NC% FFmpeg setup completed!
echo %BLUE%[INFO]%NC% FFmpeg version:
"%MSYS2_PATH%\bin\ffmpeg.exe" -version | findstr "ffmpeg version"

echo.
echo %BLUE%[INFO]%NC% ProRes codec support:
"%MSYS2_PATH%\bin\ffmpeg.exe" -codecs 2>nul | findstr "prores"

echo.
echo %BLUE%[INFO]%NC% Setup summary:
echo   - Headers: %FFMPEG_DIR%\include
echo   - Libraries: %FFMPEG_DIR%\lib
echo   - DLLs: %FFMPEG_DIR%\bin
echo   - ProRes support: Enabled

echo %GREEN%[SUCCESS]%NC% FFmpeg is ready for ProRes development!
pause 