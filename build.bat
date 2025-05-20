@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo Building HYPER-PLAYER
echo ===================================================

:: Kill all Qt and related processes
echo [INFO] Terminating all Qt processes...
taskkill /F /IM HYPER-PLAYER.exe 2>nul
taskkill /F /IM qmlscene.exe 2>nul
taskkill /F /IM windeployqt.exe 2>nul
taskkill /F /IM designer.exe 2>nul
taskkill /F /IM qmlviewer.exe 2>nul
taskkill /F /IM QtWebEngineProcess.exe 2>nul
taskkill /F /IM qmlplugindump.exe 2>nul
taskkill /F /IM qmllint.exe 2>nul
taskkill /F /IM qmltestrunner.exe 2>nul
taskkill /F /IM qmlprofiler.exe 2>nul
taskkill /F /IM qmltime.exe 2>nul
taskkill /F /IM qmlimportscanner.exe 2>nul
taskkill /F /IM qmlcachegen.exe 2>nul
:: Wait a moment to ensure processes are terminated
timeout /t 3 /nobreak > nul

:: Clean up previous build files
echo [INFO] Cleaning up previous build files...
if exist "build" (
    rd /s /q "build" 2>nul
    timeout /t 2 /nobreak > nul
)
mkdir build

:: Clean up previous junction if it exists
if exist "C:\temp_hyperplayer_build" (
    echo [INFO] Removing previous junction...
    rmdir "C:\temp_hyperplayer_build" /s /q
    timeout /t 2 > nul
)

:: Create a junction point to work around space in path issues
set TEMP_BUILD_DIR=C:\temp_hyperplayer_build
mkdir "%TEMP_BUILD_DIR%"

:: Get the current directory
set CURRENT_DIR=%CD%

:: Create a symbolic link (junction) to avoid path with spaces
echo [INFO] Creating temporary build directory without spaces in path
mklink /J "%TEMP_BUILD_DIR%\source" "%CURRENT_DIR%"

:: Create build directory in temp location
mkdir "%TEMP_BUILD_DIR%\source\build"
cd /d "%TEMP_BUILD_DIR%\source\build"

:: Check if MPV libraries are available (new location)
if exist "..\external\libs\windows\include\client.h" (
    if exist "..\external\libs\windows\bin\libmpv-2.dll" (
        set MPV_AVAILABLE=true
        echo [INFO] MPV libraries found in external\libs\windows - building with full media playback support
    ) else (
        set MPV_AVAILABLE=false
        echo [INFO] MPV DLL not found - checking fallback location
    )
) else (
    set MPV_AVAILABLE=false
    echo [INFO] MPV headers not found in new location - checking fallback location
)

:: Check fallback location if not found in the new path
if "!MPV_AVAILABLE!"=="false" (
    if exist "..\external\mpv-dev\include\client.h" (
        if exist "..\external\mpv-dev\bin\libmpv-2.dll" (
            set MPV_AVAILABLE=true
            echo [INFO] MPV libraries found in external\mpv-dev - building with full media playback support
        ) else (
            set MPV_AVAILABLE=false
            echo [INFO] MPV DLL not found - building simplified version
        )
    ) else (
        set MPV_AVAILABLE=false
        echo [INFO] MPV headers not found - building simplified version
    )
)

echo.
echo [INFO] To install MPV libraries, run extract-mpv.bat
echo.

:: Add MinGW bin directory to PATH
set PATH=C:\Qt\6.9.0\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;%PATH%

echo Running CMake...
cmake -G "MinGW Makefiles" -DCMAKE_PREFIX_PATH=C:/Qt/6.9.0/mingw_64 ..

echo.
echo Building the project...
cmake --build .

set BUILD_STATUS=%ERRORLEVEL%

if "%BUILD_STATUS%"=="0" (
    echo [INFO] Copying build output to original directory
    
    :: Create the build directory in the original location if it doesn't exist
    if not exist "%CURRENT_DIR%\build" mkdir "%CURRENT_DIR%\build"
    
    :: Copy the executable
    copy "HYPER-PLAYER.exe" "%CURRENT_DIR%\build" /Y
    
    :: Copy MPV DLL
    if exist "..\external\libs\windows\bin\libmpv-2.dll" (
        copy "..\external\libs\windows\bin\libmpv-2.dll" "%CURRENT_DIR%\build" /Y
    ) else if exist "..\external\mpv-dev\bin\libmpv-2.dll" (
        copy "..\external\mpv-dev\bin\libmpv-2.dll" "%CURRENT_DIR%\build" /Y
    )
    
    :: Run windeployqt
    echo [INFO] Running windeployqt...
    windeployqt "%CURRENT_DIR%\build\HYPER-PLAYER.exe" --qmldir="%CURRENT_DIR%\qml"
    timeout /t 5 > nul
    
    :: Copy QML files
    echo [INFO] Copying QML files...
    if not exist "%CURRENT_DIR%\build\qml" mkdir "%CURRENT_DIR%\build\qml"
    xcopy /Y /E /I "%CURRENT_DIR%\qml\*" "%CURRENT_DIR%\build\qml\"
    
    :: Make sure core QML component folders exist
    if not exist "%CURRENT_DIR%\build\qml\core" mkdir "%CURRENT_DIR%\build\qml\core"
    if not exist "%CURRENT_DIR%\build\qml\ui" mkdir "%CURRENT_DIR%\build\qml\ui"
    if not exist "%CURRENT_DIR%\build\qml\utils" mkdir "%CURRENT_DIR%\build\qml\utils"
    if not exist "%CURRENT_DIR%\build\qml\widgets" mkdir "%CURRENT_DIR%\build\qml\widgets"

    :: Copy assets directory (icons and other resources)
    echo [INFO] Copying assets...
    if not exist "%CURRENT_DIR%\build\assets" mkdir "%CURRENT_DIR%\build\assets"
    if not exist "%CURRENT_DIR%\build\assets\icons" mkdir "%CURRENT_DIR%\build\assets\icons"
    xcopy /Y /E /I "%CURRENT_DIR%\assets\icons\*" "%CURRENT_DIR%\build\assets\icons\"
)

:: Return to original directory and clean up
cd /d "%CURRENT_DIR%"
echo [INFO] Cleaning up temporary build directory
timeout /t 3 > nul
rmdir "%TEMP_BUILD_DIR%\source"
rmdir "%TEMP_BUILD_DIR%"

if "%BUILD_STATUS%" NEQ "0" (
    echo.
    echo [ERROR] Build failed!
    echo.
    echo Possible solutions:
    echo 1. Make sure you have CMake installed and in your PATH
    echo 2. Make sure you have a C++ compiler installed (e.g., MSVC, MinGW)
    echo 3. Make sure Qt6 is properly installed and findable by CMake
    echo.
    exit /b 1
) else (
    echo.
    echo [SUCCESS] Build complete!
    if "!MPV_AVAILABLE!"=="true" (
        echo [INFO] Full version with MPV support has been built
    ) else (
        echo [INFO] Basic version without MPV support has been built
        echo [INFO] To build with MPV support, make sure MPV libraries are installed correctly
    )
    echo.
)

endlocal 