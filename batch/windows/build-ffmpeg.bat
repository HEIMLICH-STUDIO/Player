@echo off
setlocal

:: Set console to UTF-8 for proper character display
chcp 65001 >nul

echo ====================================================
echo Building Player by HEIMLICH with FFmpeg Engine
echo ====================================================

:: Navigate to project root
cd ..\..

:: Create output directories if they don't exist
if not exist "output" mkdir output
if not exist "output\builds" mkdir output\builds
if not exist "output\logs" mkdir output\logs
if not exist "output\temp" mkdir output\temp

:: Extract version from CMakeLists.txt using simple token extraction
echo [INFO] Extracting version information from CMakeLists.txt...

:: Extract version numbers using simple token approach
for /f "tokens=2" %%i in ('findstr "set(PROJECT_VERSION_MAJOR" CMakeLists.txt') do set MAJOR_RAW=%%i
for /f "tokens=2" %%i in ('findstr "set(PROJECT_VERSION_MINOR" CMakeLists.txt') do set MINOR_RAW=%%i
for /f "tokens=2" %%i in ('findstr "set(PROJECT_VERSION_PATCH" CMakeLists.txt') do set PATCH_RAW=%%i

:: Remove trailing parentheses
set MAJOR=%MAJOR_RAW:)=%
set MINOR=%MINOR_RAW:)=%
set PATCH=%PATCH_RAW:)=%

set CURRENT_VERSION=%MAJOR%.%MINOR%.%PATCH%
echo [INFO] Current project version: %CURRENT_VERSION%
echo.

:: Step 1: Kill all Qt and related processes FIRST
echo [STEP 1] Terminating all Qt and related processes...
taskkill /F /IM Player-by-HEIMLICH.exe 2>nul
taskkill /F /IM qmlscene.exe 2>nul
taskkill /F /IM windeployqt.exe 2>nul
taskkill /F /IM cmake.exe 2>nul
taskkill /F /IM mingw32-make.exe 2>nul
taskkill /F /IM g++.exe 2>nul
taskkill /F /IM gcc.exe 2>nul
taskkill /F /IM ld.exe 2>nul
taskkill /F /IM moc.exe 2>nul
taskkill /F /IM rcc.exe 2>nul
taskkill /F /IM uic.exe 2>nul
timeout /t 3 /nobreak > nul
echo [SUCCESS] All processes terminated!
echo.

:: Step 2: Convert PNG icon to ICO format
echo [STEP 2] Converting icon to ICO format...
powershell -ExecutionPolicy Bypass -File batch\windows\convert-icon.ps1

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Icon conversion failed!
    pause
    exit /b 1
)

echo [SUCCESS] Icon converted successfully!

:: Verify icon exists
if not exist "output\temp\icon_win.ico" (
    echo [ERROR] icon_win.ico not found after conversion!
    pause
    exit /b 1
)
echo [INFO] Icon file verified: output\temp\icon_win.ico
echo.

:: Step 3: Check FFmpeg dependencies
echo [STEP 3] Checking FFmpeg dependencies...

:: Check if vcpkg or system FFmpeg is available
set FFMPEG_FOUND=0

:: Try vcpkg first
if exist "C:\vcpkg\installed\x64-windows\lib\avformat.lib" (
    echo [SUCCESS] FFmpeg found via vcpkg!
    set FFMPEG_PATH=C:\vcpkg\installed\x64-windows
    set FFMPEG_FOUND=1
) else if exist "C:\vcpkg\installed\x64-mingw-dynamic\lib\libavformat.a" (
    echo [SUCCESS] FFmpeg found via vcpkg (mingw)!
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

:: Step 4: Clean up previous build files
echo [STEP 4] Cleaning up previous build files...
if exist "build" (
    rd /s /q "build" 2>nul
    timeout /t 2 /nobreak > nul
)
mkdir build

:: Clean up previous junction if it exists
if exist "C:\temp_ffmpeg_build" (
    echo [INFO] Removing previous junction...
    rmdir "C:\temp_ffmpeg_build" /s /q
    timeout /t 2 > nul
)

:: Create a junction point to work around space in path issues
set TEMP_BUILD_DIR=C:\temp_ffmpeg_build
mkdir "%TEMP_BUILD_DIR%"

:: Get the current directory
set CURRENT_DIR=%CD%

:: Create a symbolic link (junction) to avoid path with spaces
echo [INFO] Creating temporary build directory without spaces in path
mklink /J "%TEMP_BUILD_DIR%\source" "%CURRENT_DIR%"

:: Create build directory in temp location
mkdir "%TEMP_BUILD_DIR%\source\build"
cd /d "%TEMP_BUILD_DIR%\source\build"

:: Copy icon to multiple locations to ensure it's found
echo [INFO] Copying icon for resource compilation...
copy "..\output\temp\icon_win.ico" "." /Y
copy "..\output\temp\icon_win.ico" "icon_win.ico" /Y
copy "..\output\temp\icon_win.ico" "..\icon_win.ico" /Y
copy "..\output\temp\icon_win.ico" "..\..\assets\Images\icon_win.ico" /Y

:: Add MinGW bin directory to PATH
set PATH=C:\Qt\6.9.0\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;%PATH%

:: Add pkg-config and FFmpeg to PATH if available
if exist "C:\msys64\mingw64\bin" (
    set PATH=C:\msys64\mingw64\bin;%PATH%
    echo [INFO] Added MSYS2 to PATH for FFmpeg
)

echo [STEP 5] Running CMake for FFmpeg build...

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
    cd /d "%CURRENT_DIR%"
    rmdir "%TEMP_BUILD_DIR%\source"
    rmdir "%TEMP_BUILD_DIR%"
    pause
    exit /b 1
)

:: Verify resources.rc was generated
if exist "resources.rc" (
    echo [SUCCESS] resources.rc generated successfully!
) else (
    echo [WARNING] resources.rc not found in build directory!
)

echo.
echo [STEP 6] Building the application with FFmpeg engine...
cmake --build . --config Release -j4

set BUILD_STATUS=%ERRORLEVEL%

if "%BUILD_STATUS%"=="0" (
    echo [STEP 7] Copying build output to original directory
    
    :: Create the build directory in the original location if it doesn't exist
    if not exist "%CURRENT_DIR%\build" mkdir "%CURRENT_DIR%\build"
    
    :: Copy the executable
    copy "Player-by-HEIMLICH.exe" "%CURRENT_DIR%\build" /Y
    
    :: Run windeployqt
    echo [INFO] Running windeployqt...
    windeployqt "%CURRENT_DIR%\build\Player-by-HEIMLICH.exe" --qmldir="%CURRENT_DIR%\qml" --release
    timeout /t 3 > nul
    
    :: Copy QML files
    echo [INFO] Copying QML files...
    if not exist "%CURRENT_DIR%\build\qml" mkdir "%CURRENT_DIR%\build\qml"
    xcopy /Y /E /I "%CURRENT_DIR%\qml\*" "%CURRENT_DIR%\build\qml\"
    
    :: Copy assets directory
    echo [INFO] Copying assets...
    if not exist "%CURRENT_DIR%\build\assets" mkdir "%CURRENT_DIR%\build\assets"
    xcopy /Y /E /I "%CURRENT_DIR%\assets\*" "%CURRENT_DIR%\build\assets\"
    
    :: Copy FFmpeg DLLs if found in system
    echo [INFO] Checking for FFmpeg DLLs to copy...
    
    :: Try to find and copy FFmpeg DLLs from common locations
    set DLL_COPIED=0
    
    :: Check vcpkg location
    if exist "C:\vcpkg\installed\x64-windows\bin\avformat*.dll" (
        echo [INFO] Copying FFmpeg DLLs from vcpkg...
        copy "C:\vcpkg\installed\x64-windows\bin\av*.dll" "%CURRENT_DIR%\build\" /Y 2>nul
        copy "C:\vcpkg\installed\x64-windows\bin\sw*.dll" "%CURRENT_DIR%\build\" /Y 2>nul
        set DLL_COPIED=1
    ) else if exist "C:\vcpkg\installed\x64-mingw-dynamic\bin\libav*.dll" (
        echo [INFO] Copying FFmpeg DLLs from vcpkg (mingw)...
        copy "C:\vcpkg\installed\x64-mingw-dynamic\bin\libav*.dll" "%CURRENT_DIR%\build\" /Y 2>nul
        copy "C:\vcpkg\installed\x64-mingw-dynamic\bin\libsw*.dll" "%CURRENT_DIR%\build\" /Y 2>nul
        set DLL_COPIED=1
    ) else if exist "C:\msys64\mingw64\bin\libav*.dll" (
        echo [INFO] Copying FFmpeg DLLs from MSYS2...
        copy "C:\msys64\mingw64\bin\libav*.dll" "%CURRENT_DIR%\build\" /Y 2>nul
        copy "C:\msys64\mingw64\bin\libsw*.dll" "%CURRENT_DIR%\build\" /Y 2>nul
        set DLL_COPIED=1
    )
    
    if %DLL_COPIED% EQU 1 (
        echo [SUCCESS] FFmpeg DLLs copied to build directory!
    ) else (
        echo [WARNING] FFmpeg DLLs not found in common locations
        echo [INFO] Make sure FFmpeg DLLs are available in system PATH
    )
    
    :: Return to original directory
    cd /d "%CURRENT_DIR%"
    
    :: Copy build to output directory
    echo [INFO] Copying build to output directory...
    if not exist "output\builds\%CURRENT_VERSION%" mkdir "output\builds\%CURRENT_VERSION%"
    xcopy /Y /E /I "build\*" "output\builds\%CURRENT_VERSION%\"
    
    echo.
    echo ====================================================
    echo SUCCESS: FFmpeg Player built successfully!
    echo ====================================================
    echo Version: %CURRENT_VERSION%
    echo Build location: build\Player-by-HEIMLICH.exe
    echo Archive location: output\builds\%CURRENT_VERSION%\
    echo.
    echo FFmpeg Video Engine Features:
    echo - Professional video playback with FFmpeg
    echo - Wide format support (MP4, MKV, AVI, MOV, etc.)
    echo - Hardware acceleration support
    echo - Advanced video processing capabilities
    echo.
    
) else (
    echo [ERROR] Application build failed!
    echo [ERROR] Check the error messages above for details.
    
    :: Save error log to output/logs
    echo [INFO] Saving error log...
    echo FFmpeg build failed at %DATE% %TIME% > "output\logs\ffmpeg_build_error_%CURRENT_VERSION%.log"
)

:: Clean up temporary build directory
echo.
echo [INFO] Cleaning up temporary build directory...
cd /d "%CURRENT_DIR%"
timeout /t 2 > nul
rmdir "%TEMP_BUILD_DIR%\source" 2>nul
rmdir "%TEMP_BUILD_DIR%" 2>nul

if "%BUILD_STATUS%" NEQ "0" (
    echo.
    echo [ERROR] Build failed! Check the errors above.
    echo [INFO] Error log saved to output\logs\ffmpeg_build_error_%CURRENT_VERSION%.log
    cd batch\windows
    pause
    exit /b 1
) else (
    echo.
    echo ====================================================
    echo SUCCESS: FFmpeg build complete!
    echo ====================================================
    echo Ready to run: build\Player-by-HEIMLICH.exe
    echo.
    echo [TIP] Use 'run-app-ffmpeg.bat' to start the application
    echo.
    cd batch\windows
)

endlocal 