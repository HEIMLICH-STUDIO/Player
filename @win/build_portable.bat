@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Player by HEIMLICH® Portable Build
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
set "BUILD_DIR=%PROJECT_ROOT%\build_portable"

echo %BLUE%[INFO]%NC% Project root: %PROJECT_ROOT%
echo %BLUE%[INFO]%NC% Portable build directory: %BUILD_DIR%

:: Check MSYS2 path
if not exist "%MSYS2_PATH%\gcc.exe" (
    echo %RED%[ERROR]%NC% MSYS2 MinGW64 is not installed.
    pause
    exit /b 1
)

:: Add MSYS2 to PATH
set "PATH=%MSYS2_PATH%;%PATH%"

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
echo %BLUE%[INFO]%NC% Preparing portable build directory...
if exist "%BUILD_DIR%" (
    echo %YELLOW%[INFO]%NC% Cleaning existing build directory...
    rmdir /s /q "%BUILD_DIR%" 2>nul
)
mkdir "%BUILD_DIR%"

:: Configure CMake for regular build (not static)
echo %BLUE%[INFO]%NC% Configuring CMake for portable build...
cd /d "%BUILD_DIR%"

cmake .. -G "MinGW Makefiles" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_PREFIX_PATH="C:/msys64/mingw64"

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

:: Create portable package
echo %BLUE%[INFO]%NC% Creating portable package...

:: Copy all essential DLLs systematically
echo %BLUE%[INFO]%NC% Copying all required DLLs...

:: FFmpeg DLLs
copy "%PROJECT_ROOT%\external\ffmpeg\bin\*.dll" . >nul 2>&1

:: Core runtime DLLs
copy "%MSYS2_PATH%\libgcc_s_seh-1.dll" . >nul 2>&1
copy "%MSYS2_PATH%\libstdc++-6.dll" . >nul 2>&1
copy "%MSYS2_PATH%\libwinpthread-1.dll" . >nul 2>&1

:: Qt6 DLLs
copy "%MSYS2_PATH%\Qt6Core.dll" . >nul 2>&1
copy "%MSYS2_PATH%\Qt6Gui.dll" . >nul 2>&1
copy "%MSYS2_PATH%\Qt6Quick.dll" . >nul 2>&1
copy "%MSYS2_PATH%\Qt6Qml.dll" . >nul 2>&1
copy "%MSYS2_PATH%\Qt6QuickControls2.dll" . >nul 2>&1
copy "%MSYS2_PATH%\Qt6Widgets.dll" . >nul 2>&1
copy "%MSYS2_PATH%\Qt6OpenGL.dll" . >nul 2>&1
copy "%MSYS2_PATH%\Qt6Network.dll" . >nul 2>&1

:: Qt6 platform plugins
if not exist "platforms" mkdir "platforms"
copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qwindows.dll" "platforms\" >nul 2>&1
copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qminimal.dll" "platforms\" >nul 2>&1

:: Qt6 image format plugins
if not exist "imageformats" mkdir "imageformats"
copy "C:\msys64\mingw64\share\qt6\plugins\imageformats\*.dll" "imageformats\" >nul 2>&1

:: Copy ALL multimedia and codec DLLs to ensure compatibility
echo %BLUE%[INFO]%NC% Copying multimedia libraries...
for %%f in (
    "libfreetype-6.dll" "libfontconfig-1.dll" "libharfbuzz-0.dll"
    "libglib-2.0-0.dll" "libintl-8.dll" "libiconv-2.dll" "libpcre2-8-0.dll"
    "libexpat-1.dll" "libpng16-16.dll" "zlib1.dll" "libgraphite2.dll"
    "libbz2-1.dll" "libgme.dll" "libmodplug-1.dll" "librtmp-1.dll"
    "libsrt.dll" "libgnutls-30.dll" "libhogweed-6.dll" "libnettle-8.dll"
    "libgmp-10.dll" "libtasn1-6.dll" "libunistring-5.dll" "libidn2-0.dll"
    "libp11-kit-0.dll" "libffi-8.dll" "libssl-3-x64.dll" "libcrypto-3-x64.dll"
    "libbluray-2.dll"
) do (
    if exist "%MSYS2_PATH%\%%~f" (
        copy "%MSYS2_PATH%\%%~f" . >nul 2>&1
    )
)

:: Copy video codec DLLs
echo %BLUE%[INFO]%NC% Copying video codec libraries...
for %%f in (
    "libx264-164.dll" "libx265.dll" "libvpx-1.dll" "libaom.dll" "libdav1d-7.dll"
    "librav1e.dll" "libSvtAv1Enc.dll" "libtheora-0.dll" "libvorbis-0.dll"
    "libopus-0.dll" "libmp3lame-0.dll" "libflac-12.dll" "libspeex-1.dll"
    "libgsm.dll" "liblc3-1.dll" "libfdk-aac-2.dll" "libtwolame-0.dll"
    "libwavpack-1.dll" "libva.dll" "libva_win32.dll" "libcairo-2.dll"
    "libvpl-2.dll" "libgobject-2.0-0.dll" "libxml2-2.dll" "libssh.dll"
    "libssh2-1.dll" "libjxl.dll" "libjxl_threads.dll" "libjxl_cms.dll"
) do (
    if exist "%MSYS2_PATH%\%%~f" (
        copy "%MSYS2_PATH%\%%~f" . >nul 2>&1
    )
)

:: Copy image format DLLs
echo %BLUE%[INFO]%NC% Copying image format libraries...
for %%f in (
    "libjpeg-8.dll" "libtiff-6.dll" "libwebp-7.dll" "libwebpmux-3.dll"
    "libwebpdemux-2.dll" "libheif-1.dll" "libde265-0.dll" "libopenjp2-7.dll"
    "libsharpyuv-0.dll" "libjbig-0.dll" "libLerc.dll" "libdeflate.dll"
    "liblzma-5.dll" "libzstd.dll" "libbrotlidec.dll" "libbrotlicommon.dll"
    "libpixman-1-0.dll"
) do (
    if exist "%MSYS2_PATH%\%%~f" (
        copy "%MSYS2_PATH%\%%~f" . >nul 2>&1
    )
)

:: Copy additional system libraries that might be needed
echo %BLUE%[INFO]%NC% Copying additional system libraries...
for %%f in (
    "libgio-2.0-0.dll" "libsoxr-0.dll" "libsamplerate-0.dll"
    "libogg-0.dll" "libvorbisenc-2.dll" "libvorbisfile-3.dll"
    "libtheoradec-1.dll" "libtheoraenc-1.dll" "libxvidcore.dll"
) do (
    if exist "%MSYS2_PATH%\%%~f" (
        copy "%MSYS2_PATH%\%%~f" . >nul 2>&1
    )
)

:: Create a launcher script that sets up the environment
echo %BLUE%[INFO]%NC% Creating launcher script...
echo @echo off > "Player-by-HEIMLICH-Portable.bat"
echo cd /d "%%~dp0" >> "Player-by-HEIMLICH-Portable.bat"
echo start "" "Player-by-HEIMLICH.exe" %%* >> "Player-by-HEIMLICH-Portable.bat"

:: Create README for portable version
echo %BLUE%[INFO]%NC% Creating README...
echo Player by HEIMLICH® - Portable Version > README.txt
echo ========================================= >> README.txt
echo. >> README.txt
echo This is a portable version that includes all necessary libraries. >> README.txt
echo. >> README.txt
echo To run the player: >> README.txt
echo 1. Double-click "Player-by-HEIMLICH-Portable.bat" >> README.txt
echo 2. Or directly run "Player-by-HEIMLICH.exe" >> README.txt
echo. >> README.txt
echo No installation required! >> README.txt

:: Check final size and dependencies
echo %BLUE%[INFO]%NC% Checking portable package...
echo %YELLOW%[INFO]%NC% Package contents:
dir /b *.dll | find /c ".dll" > temp_count.txt
set /p dll_count=<temp_count.txt
del temp_count.txt
echo   - %dll_count% DLL files
echo   - Player executable
echo   - Platform plugins
echo   - Image format plugins

:: Test dependencies one more time
echo %BLUE%[INFO]%NC% Final dependency check...
objdump -p Player-by-HEIMLICH.exe | findstr "DLL Name:" > final_deps.txt
echo %BLUE%[INFO]%NC% Required DLLs:
type final_deps.txt
del final_deps.txt

:: Success message
echo.
echo %GREEN%[SUCCESS]%NC% Portable build completed!
echo %BLUE%[INFO]%NC% Portable package: %BUILD_DIR%
echo %YELLOW%[INFO]%NC% This package should run on any Windows system without additional dependencies.
echo.

:: Ask to test
set /p "test=Do you want to test the portable build? (y/N): "
if /i "%test%"=="y" (
    echo %BLUE%[INFO]%NC% Testing portable build...
    start "" "Player-by-HEIMLICH-Portable.bat"
)

echo %BLUE%[INFO]%NC% Portable build script completed
pause 