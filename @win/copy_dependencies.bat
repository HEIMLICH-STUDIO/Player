@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   DLL Dependency Resolver
echo ========================================

:: Color settings
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

set "BUILD_DIR=%~dp0..\build"
set "MSYS2_BIN=C:\msys64\mingw64\bin"

echo %BLUE%[INFO]%NC% Resolving DLL dependencies for Player-by-HEIMLICH.exe
echo %BLUE%[INFO]%NC% Build directory: %BUILD_DIR%

cd /d "%BUILD_DIR%"

:: List of additional DLLs that might be needed
set "ADDITIONAL_DLLS=libva.dll libva_win32.dll libcairo-2.dll libdav1d-7.dll libaom.dll libvpl-2.dll libgobject-2.0-0.dll libxml2-2.dll libssh.dll libssh2-1.dll libgio-2.0-0.dll libpixman-1-0.dll liblzma-5.dll libzstd.dll libbrotlidec.dll libbrotlicommon.dll libsharpyuv-0.dll libwebp-7.dll libwebpmux-3.dll libwebpdemux-2.dll libjpeg-8.dll libtiff-6.dll libdeflate.dll libjbig-0.dll libLerc.dll libopenjp2-7.dll librav1e.dll libSvtAv1Enc.dll libx264-164.dll libx265.dll libxvidcore.dll libvpx-1.dll libtheora-0.dll libtheoradec-1.dll libtheoraenc-1.dll libogg-0.dll libvorbis-0.dll libvorbisenc-2.dll libvorbisfile-3.dll libopus-0.dll libspeex-1.dll libflac-12.dll libmp3lame-0.dll libtwolame-0.dll libwavpack-1.dll libsoxr-0.dll libsamplerate-0.dll libfdk-aac-2.dll libjxl.dll libjxl_cms.dll libjxl_threads.dll liblc3-1.dll libgsm.dll"

echo %BLUE%[INFO]%NC% Copying additional DLL dependencies...

for %%d in (%ADDITIONAL_DLLS%) do (
    if exist "%MSYS2_BIN%\%%d" (
        if not exist "%%d" (
            echo %YELLOW%[COPY]%NC% %%d
            copy "%MSYS2_BIN%\%%d" . >nul 2>&1
        )
    )
)

:: Copy additional Cairo dependencies
echo %BLUE%[INFO]%NC% Copying Cairo dependencies...
copy "%MSYS2_BIN%\libcairo-gobject-2.dll" . >nul 2>&1
copy "%MSYS2_BIN%\libcairo-script-interpreter-2.dll" . >nul 2>&1

:: Copy additional GLib dependencies
echo %BLUE%[INFO]%NC% Copying GLib dependencies...
copy "%MSYS2_BIN%\libgmodule-2.0-0.dll" . >nul 2>&1
copy "%MSYS2_BIN%\libgthread-2.0-0.dll" . >nul 2>&1

:: Copy additional image format dependencies
echo %BLUE%[INFO]%NC% Copying image format dependencies...
copy "%MSYS2_BIN%\liblcms2-2.dll" . >nul 2>&1
copy "%MSYS2_BIN%\libheif-1.dll" . >nul 2>&1
copy "%MSYS2_BIN%\libde265-0.dll" . >nul 2>&1

echo %GREEN%[SUCCESS]%NC% Dependency resolution completed!
echo %BLUE%[INFO]%NC% Try running the player now.

pause 