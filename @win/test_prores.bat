@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   ProRes Test File Generator
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
set "OUTPUT_DIR=%PROJECT_ROOT%\test_files"

echo %BLUE%[INFO]%NC% Generating ProRes test files...
echo %BLUE%[INFO]%NC% Output directory: %OUTPUT_DIR%

:: Check if FFmpeg is available
if not exist "%MSYS2_PATH%\ffmpeg.exe" (
    echo %RED%[ERROR]%NC% FFmpeg not found at: %MSYS2_PATH%\ffmpeg.exe
    echo %YELLOW%[INFO]%NC% Please install MSYS2 and FFmpeg first
    pause
    exit /b 1
)

:: Check ProRes support
echo %BLUE%[INFO]%NC% Checking ProRes support...
"%MSYS2_PATH%\ffmpeg.exe" -codecs 2>nul | findstr "prores" >nul
if errorlevel 1 (
    echo %RED%[ERROR]%NC% ProRes codec not found in FFmpeg
    pause
    exit /b 1
) else (
    echo %GREEN%[OK]%NC% ProRes codec support confirmed
)

:: Create output directory
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
    echo %BLUE%[INFO]%NC% Created output directory: %OUTPUT_DIR%
)

:: Generate different ProRes profiles
echo.
echo %BLUE%[INFO]%NC% Generating ProRes test files...

:: ProRes Proxy (Profile 0)
echo %BLUE%[INFO]%NC% Generating ProRes Proxy...
"%MSYS2_PATH%\ffmpeg.exe" -f lavfi -i testsrc=duration=10:size=1920x1080:rate=24 ^
    -c:v prores_ks -profile:v 0 -pix_fmt yuv422p ^
    "%OUTPUT_DIR%\test_prores_proxy.mov" -y
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to generate ProRes Proxy
) else (
    echo %GREEN%[OK]%NC% ProRes Proxy generated
)

:: ProRes LT (Profile 1)
echo %BLUE%[INFO]%NC% Generating ProRes LT...
"%MSYS2_PATH%\ffmpeg.exe" -f lavfi -i testsrc=duration=10:size=1920x1080:rate=24 ^
    -c:v prores_ks -profile:v 1 -pix_fmt yuv422p ^
    "%OUTPUT_DIR%\test_prores_lt.mov" -y
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to generate ProRes LT
) else (
    echo %GREEN%[OK]%NC% ProRes LT generated
)

:: ProRes Standard (Profile 2)
echo %BLUE%[INFO]%NC% Generating ProRes Standard...
"%MSYS2_PATH%\ffmpeg.exe" -f lavfi -i testsrc=duration=10:size=1920x1080:rate=24 ^
    -c:v prores_ks -profile:v 2 -pix_fmt yuv422p ^
    "%OUTPUT_DIR%\test_prores_standard.mov" -y
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to generate ProRes Standard
) else (
    echo %GREEN%[OK]%NC% ProRes Standard generated
)

:: ProRes HQ (Profile 3)
echo %BLUE%[INFO]%NC% Generating ProRes HQ...
"%MSYS2_PATH%\ffmpeg.exe" -f lavfi -i testsrc=duration=10:size=1920x1080:rate=24 ^
    -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le ^
    "%OUTPUT_DIR%\test_prores_hq.mov" -y
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to generate ProRes HQ
) else (
    echo %GREEN%[OK]%NC% ProRes HQ generated
)

:: ProRes 4444 (Profile 4)
echo %BLUE%[INFO]%NC% Generating ProRes 4444...
"%MSYS2_PATH%\ffmpeg.exe" -f lavfi -i testsrc=duration=10:size=1920x1080:rate=24 ^
    -c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le ^
    "%OUTPUT_DIR%\test_prores_4444.mov" -y
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to generate ProRes 4444
) else (
    echo %GREEN%[OK]%NC% ProRes 4444 generated
)

:: Generate a colorful test pattern
echo %BLUE%[INFO]%NC% Generating colorful test pattern...
"%MSYS2_PATH%\ffmpeg.exe" -f lavfi -i "testsrc2=duration=15:size=1920x1080:rate=30" ^
    -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le ^
    "%OUTPUT_DIR%\test_colorful_prores.mov" -y
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to generate colorful test pattern
) else (
    echo %GREEN%[OK]%NC% Colorful test pattern generated
)

:: Generate a moving test pattern
echo %BLUE%[INFO]%NC% Generating moving test pattern...
"%MSYS2_PATH%\ffmpeg.exe" -f lavfi -i "mandelbrot=size=1920x1080:rate=24" -t 8 ^
    -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le ^
    "%OUTPUT_DIR%\test_mandelbrot_prores.mov" -y
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Failed to generate moving test pattern
) else (
    echo %GREEN%[OK]%NC% Moving test pattern generated
)

:: Display file information
echo.
echo %GREEN%[SUCCESS]%NC% ProRes test files generated!
echo %BLUE%[INFO]%NC% Generated files:

for %%f in ("%OUTPUT_DIR%\*.mov") do (
    echo   - %%~nxf
)

echo.
echo %BLUE%[INFO]%NC% File details:
for %%f in ("%OUTPUT_DIR%\*.mov") do (
    echo.
    echo %YELLOW%File:%NC% %%~nxf
    "%MSYS2_PATH%\ffprobe.exe" -v quiet -select_streams v:0 -show_entries stream=codec_name,profile,width,height,pix_fmt -of csv=p=0 "%%f" 2>nul
)

echo.
echo %BLUE%[INFO]%NC% You can now test these files with the player:
echo   @win\run.bat "%OUTPUT_DIR%\test_prores_hq.mov"

pause 