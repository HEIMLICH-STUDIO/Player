@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Player by HEIMLICH® Build Script
echo ========================================

:: Color settings
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Environment variables
set "MSYS2_PATH=C:\msys64\mingw64\bin"
set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build"

echo %BLUE%[INFO]%NC% Project root: %PROJECT_ROOT%
echo %BLUE%[INFO]%NC% Build directory: %BUILD_DIR%

:: Check MSYS2 path
if not exist "%MSYS2_PATH%\gcc.exe" (
    echo %RED%[ERROR]%NC% MSYS2 MinGW64 is not installed.
    echo %YELLOW%[INFO]%NC% Please install MSYS2 and run the following commands:
    echo   pacman -S mingw-w64-x86_64-toolchain
    echo   pacman -S mingw-w64-x86_64-cmake
    echo   pacman -S mingw-w64-x86_64-qt6
    echo   pacman -S mingw-w64-x86_64-ffmpeg
    pause
    exit /b 1
)

:: Add MSYS2 to PATH
set "PATH=%MSYS2_PATH%;%PATH%"

:: Check compiler
echo %BLUE%[INFO]%NC% Checking compiler...
gcc --version >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%NC% GCC compiler not found.
    pause
    exit /b 1
)

:: Check FFmpeg
echo %BLUE%[INFO]%NC% Checking FFmpeg...
if not exist "%PROJECT_ROOT%\external\ffmpeg\include\libavformat\avformat.h" (
    echo %YELLOW%[WARNING]%NC% FFmpeg libraries not found. Installing...
    call "%~dp0setup_ffmpeg.bat"
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% FFmpeg installation failed
        pause
        exit /b 1
    )
)

:: Prepare build directory
echo %BLUE%[INFO]%NC% Preparing build directory...
if exist "%BUILD_DIR%" (
    echo %YELLOW%[INFO]%NC% Cleaning existing build directory...
    rmdir /s /q "%BUILD_DIR%" 2>nul
)
mkdir "%BUILD_DIR%"

:: Configure CMake
echo %BLUE%[INFO]%NC% Configuring CMake...
cd /d "%BUILD_DIR%"
cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 (
    echo %RED%[ERROR]%NC% CMake configuration failed
    pause
    exit /b 1
)

:: Build project
echo %BLUE%[INFO]%NC% Building project...
cmake --build . --parallel 4
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Build failed
    pause
    exit /b 1
)

:: Copy FFmpeg DLLs
echo %BLUE%[INFO]%NC% Copying FFmpeg DLLs...
copy "%PROJECT_ROOT%\external\ffmpeg\bin\*.dll" . >nul 2>&1

:: Copy QML and assets files (CRITICAL!)
echo %BLUE%[INFO]%NC% Copying QML and assets files...
xcopy "%PROJECT_ROOT%\qml" "qml\" /E /I /Y >nul 2>&1
xcopy "%PROJECT_ROOT%\assets" "assets\" /E /I /Y >nul 2>&1

:: Copy additional MSYS2 dependencies
echo %BLUE%[INFO]%NC% Copying additional dependencies...
copy "C:\msys64\mingw64\bin\libbluray-2.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libgcc_s_seh-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libbz2-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libgme.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libstdc++-6.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libwinpthread-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libfreetype-6.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libfontconfig-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libharfbuzz-0.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libglib-2.0-0.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libintl-8.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libiconv-2.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libpcre2-8-0.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libexpat-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libpng16-16.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\zlib1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libgraphite2.dll" . >nul 2>&1

:: Copy Qt6 DLLs
echo %BLUE%[INFO]%NC% Copying Qt6 DLLs...
copy "C:\msys64\mingw64\bin\Qt6Core.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\Qt6Gui.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\Qt6Quick.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\Qt6Qml.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\Qt6QuickControls2.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\Qt6Widgets.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\Qt6OpenGL.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\Qt6Network.dll" . >nul 2>&1

:: Copy Qt6 dependencies (CRITICAL!)
echo %BLUE%[INFO]%NC% Copying Qt6 dependencies...
copy "C:\msys64\mingw64\bin\libb2-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libdouble-conversion.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libicuin77.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libicuuc77.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libicudt77.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libpcre2-16-0.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libmd4c.dll" . >nul 2>&1

:: Copy Qt6 platform plugins
echo %BLUE%[INFO]%NC% Copying Qt6 platform plugins...
if not exist "platforms" mkdir "platforms"
copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qwindows.dll" "platforms\" >nul 2>&1
copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qminimal.dll" "platforms\" >nul 2>&1
copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qoffscreen.dll" "platforms\" >nul 2>&1

:: Copy Qt6 image format plugins
echo %BLUE%[INFO]%NC% Copying Qt6 image format plugins...
if not exist "imageformats" mkdir "imageformats"
copy "C:\msys64\mingw64\share\qt6\plugins\imageformats\*.dll" "imageformats\" >nul 2>&1

:: Copy additional missing DLLs
echo %BLUE%[INFO]%NC% Copying additional missing DLLs...
copy "C:\msys64\mingw64\bin\libmodplug-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\librtmp-1.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libsrt.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libgnutls-30.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libhogweed-6.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libnettle-8.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libgmp-10.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libtasn1-6.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libunistring-5.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libidn2-0.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libp11-kit-0.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libffi-8.dll" . >nul 2>&1

:: Copy ALL FFmpeg and multimedia DLLs
echo %BLUE%[INFO]%NC% Copying ALL multimedia DLLs to prevent runtime errors...
for %%f in ("C:\msys64\mingw64\bin\lib*.dll") do (
    copy "%%f" . >nul 2>&1
)

:: Copy additional system libraries
echo %BLUE%[INFO]%NC% Copying system libraries...
copy "C:\msys64\mingw64\bin\libssl-3-x64.dll" . >nul 2>&1
copy "C:\msys64\mingw64\bin\libcrypto-3-x64.dll" . >nul 2>&1

:: Verify critical DLLs
echo %BLUE%[INFO]%NC% Verifying critical DLLs...
set "MISSING_DLLS="
if not exist "libbluray-2.dll" set "MISSING_DLLS=%MISSING_DLLS% libbluray-2.dll"
if not exist "libgcc_s_seh-1.dll" set "MISSING_DLLS=%MISSING_DLLS% libgcc_s_seh-1.dll"
if not exist "libbz2-1.dll" set "MISSING_DLLS=%MISSING_DLLS% libbz2-1.dll"
if not exist "libgme.dll" set "MISSING_DLLS=%MISSING_DLLS% libgme.dll"
if not exist "libmodplug-1.dll" set "MISSING_DLLS=%MISSING_DLLS% libmodplug-1.dll"
if not exist "librtmp-1.dll" set "MISSING_DLLS=%MISSING_DLLS% librtmp-1.dll"
if not exist "libsrt.dll" set "MISSING_DLLS=%MISSING_DLLS% libsrt.dll"
if not exist "libva.dll" set "MISSING_DLLS=%MISSING_DLLS% libva.dll"
if not exist "libcairo-2.dll" set "MISSING_DLLS=%MISSING_DLLS% libcairo-2.dll"
if not exist "libdav1d-7.dll" set "MISSING_DLLS=%MISSING_DLLS% libdav1d-7.dll"
if not exist "libaom.dll" set "MISSING_DLLS=%MISSING_DLLS% libaom.dll"
if not exist "libvpl-2.dll" set "MISSING_DLLS=%MISSING_DLLS% libvpl-2.dll"
if not exist "libgobject-2.0-0.dll" set "MISSING_DLLS=%MISSING_DLLS% libgobject-2.0-0.dll"
if not exist "libxml2-2.dll" set "MISSING_DLLS=%MISSING_DLLS% libxml2-2.dll"
if not exist "libssh.dll" set "MISSING_DLLS=%MISSING_DLLS% libssh.dll"
if not exist "libb2-1.dll" set "MISSING_DLLS=%MISSING_DLLS% libb2-1.dll"
if not exist "libicudt77.dll" set "MISSING_DLLS=%MISSING_DLLS% libicudt77.dll"
if not exist "swscale-8.dll" set "MISSING_DLLS=%MISSING_DLLS% swscale-8.dll"
if not exist "platforms\qwindows.dll" set "MISSING_DLLS=%MISSING_DLLS% qwindows.dll"

if not "%MISSING_DLLS%"=="" (
    echo %YELLOW%[WARNING]%NC% Some DLLs could not be copied:%MISSING_DLLS%
    echo %BLUE%[INFO]%NC% The player may still work, but some features might be limited
)

:: Success message
echo.
echo %GREEN%[SUCCESS]%NC% Build completed!
echo %BLUE%[INFO]%NC% Executable: %BUILD_DIR%\Player-by-HEIMLICH.exe
echo.

:: Ask to run
set /p "run=Do you want to run the built player? (y/N): "
if /i "%run%"=="y" (
    echo %BLUE%[INFO]%NC% Starting player...
    start "" "Player-by-HEIMLICH.exe"
)

echo %BLUE%[INFO]%NC% Build script completed
pause 