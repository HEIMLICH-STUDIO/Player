@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Player by HEIMLICH® Launcher
echo ========================================

:: Color settings
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Environment variables
set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build"
set "PLAYER_EXE=%BUILD_DIR%\Player-by-HEIMLICH.exe"

:: Check if player exists
if not exist "%PLAYER_EXE%" (
    echo %RED%[ERROR]%NC% Player executable not found: %PLAYER_EXE%
    echo %YELLOW%[INFO]%NC% Please build the project first using build.bat
    pause
    exit /b 1
)

:: Check if FFmpeg DLLs exist in build directory
if not exist "%BUILD_DIR%\avformat-61.dll" (
    echo %YELLOW%[WARNING]%NC% FFmpeg DLLs not found in build directory
    echo %BLUE%[INFO]%NC% Copying FFmpeg DLLs...
    copy "%PROJECT_ROOT%\external\ffmpeg\bin\*.dll" "%BUILD_DIR%\" >nul 2>&1
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% Failed to copy FFmpeg DLLs
        pause
        exit /b 1
    )
)

:: Check and copy missing dependencies
echo %BLUE%[INFO]%NC% Checking dependencies...
cd /d "%BUILD_DIR%"

if not exist "libbluray-2.dll" copy "C:\msys64\mingw64\bin\libbluray-2.dll" . >nul 2>&1
if not exist "libgcc_s_seh-1.dll" copy "C:\msys64\mingw64\bin\libgcc_s_seh-1.dll" . >nul 2>&1
if not exist "libbz2-1.dll" copy "C:\msys64\mingw64\bin\libbz2-1.dll" . >nul 2>&1
if not exist "libgme.dll" copy "C:\msys64\mingw64\bin\libgme.dll" . >nul 2>&1
if not exist "libstdc++-6.dll" copy "C:\msys64\mingw64\bin\libstdc++-6.dll" . >nul 2>&1
if not exist "libwinpthread-1.dll" copy "C:\msys64\mingw64\bin\libwinpthread-1.dll" . >nul 2>&1

:: Copy Qt6 DLLs if missing
if not exist "Qt6Core.dll" (
    echo %BLUE%[INFO]%NC% Copying Qt6 DLLs...
    copy "C:\msys64\mingw64\bin\Qt6Core.dll" . >nul 2>&1
    copy "C:\msys64\mingw64\bin\Qt6Gui.dll" . >nul 2>&1
    copy "C:\msys64\mingw64\bin\Qt6Quick.dll" . >nul 2>&1
    copy "C:\msys64\mingw64\bin\Qt6Qml.dll" . >nul 2>&1
    copy "C:\msys64\mingw64\bin\Qt6QuickControls2.dll" . >nul 2>&1
    copy "C:\msys64\mingw64\bin\Qt6Widgets.dll" . >nul 2>&1
    copy "C:\msys64\mingw64\bin\Qt6OpenGL.dll" . >nul 2>&1
    copy "C:\msys64\mingw64\bin\Qt6Network.dll" . >nul 2>&1
)

:: Copy Qt6 platform plugins if missing
if not exist "platforms\qwindows.dll" (
    echo %BLUE%[INFO]%NC% Copying Qt6 platform plugins...
    if not exist "platforms" mkdir "platforms"
    copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qwindows.dll" "platforms\" >nul 2>&1
    copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qminimal.dll" "platforms\" >nul 2>&1
    copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qoffscreen.dll" "platforms\" >nul 2>&1
)

:: Copy additional missing DLLs
if not exist "libmodplug-1.dll" copy "C:\msys64\mingw64\bin\libmodplug-1.dll" . >nul 2>&1
if not exist "librtmp-1.dll" copy "C:\msys64\mingw64\bin\librtmp-1.dll" . >nul 2>&1
if not exist "libsrt.dll" copy "C:\msys64\mingw64\bin\libsrt.dll" . >nul 2>&1

:: Launch player
echo %BLUE%[INFO]%NC% Starting Player by HEIMLICH®...

if "%~1"=="" (
    :: No file argument provided
    echo %BLUE%[INFO]%NC% Launching player without file
    start "" "%PLAYER_EXE%"
) else (
    :: File argument provided
    echo %BLUE%[INFO]%NC% Opening file: %~1
    start "" "%PLAYER_EXE%" "%~1"
)

echo %GREEN%[SUCCESS]%NC% Player launched successfully!
timeout /t 2 >nul 