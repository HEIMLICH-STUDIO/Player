@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Complete DLL Dependency Fixer
echo ========================================

:: Color settings
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

set "BUILD_DIR=%~dp0..\build"
set "MSYS2_BIN=C:\msys64\mingw64\bin"

echo %BLUE%[INFO]%NC% Fixing all DLL dependencies for Player-by-HEIMLICH.exe
echo %BLUE%[INFO]%NC% Build directory: %BUILD_DIR%

cd /d "%BUILD_DIR%"

:: Add MSYS2 to PATH temporarily
set "PATH=%MSYS2_BIN%;%PATH%"

echo %BLUE%[INFO]%NC% Analyzing dependencies with objdump...

:: Use objdump to find actual dependencies
objdump -p Player-by-HEIMLICH.exe | findstr "DLL Name:" > deps.txt

echo %BLUE%[INFO]%NC% Found dependencies:
type deps.txt

echo.
echo %BLUE%[INFO]%NC% Copying missing DLLs from MSYS2...

:: Read each dependency and copy if missing
for /f "tokens=3" %%i in (deps.txt) do (
    set "dll=%%i"
    if not exist "!dll!" (
        if exist "%MSYS2_BIN%\!dll!" (
            echo %YELLOW%[COPY]%NC% !dll!
            copy "%MSYS2_BIN%\!dll!" . >nul 2>&1
        ) else (
            echo %RED%[MISSING]%NC% !dll! not found in MSYS2
        )
    )
)

:: Clean up
del deps.txt

echo.
echo %BLUE%[INFO]%NC% Copying common FFmpeg codec DLLs...

:: Copy all common codec DLLs that might be needed
set "CODEC_DLLS=libx264-164.dll libx265.dll libvpx-1.dll libaom.dll libdav1d-7.dll librav1e.dll libSvtAv1Enc.dll libtheora-0.dll libvorbis-0.dll libopus-0.dll libmp3lame-0.dll libflac-12.dll libspeex-1.dll libgsm.dll liblc3-1.dll libfdk-aac-2.dll libtwolame-0.dll libwavpack-1.dll"

for %%d in (%CODEC_DLLS%) do (
    if exist "%MSYS2_BIN%\%%d" (
        if not exist "%%d" (
            echo %YELLOW%[CODEC]%NC% %%d
            copy "%MSYS2_BIN%\%%d" . >nul 2>&1
        )
    )
)

echo.
echo %BLUE%[INFO]%NC% Copying image format DLLs...

set "IMAGE_DLLS=libjpeg-8.dll libpng16-16.dll libtiff-6.dll libwebp-7.dll libjxl.dll libjxl_threads.dll libjxl_cms.dll libheif-1.dll libde265-0.dll libopenjp2-7.dll"

for %%d in (%IMAGE_DLLS%) do (
    if exist "%MSYS2_BIN%\%%d" (
        if not exist "%%d" (
            echo %YELLOW%[IMAGE]%NC% %%d
            copy "%MSYS2_BIN%\%%d" . >nul 2>&1
        )
    )
)

echo.
echo %GREEN%[SUCCESS]%NC% Dependency fixing completed!
echo %BLUE%[INFO]%NC% Try running the player now.

pause 