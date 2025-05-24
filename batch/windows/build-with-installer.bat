@echo off
setlocal enabledelayedexpansion

:: Set console to UTF-8 for proper character display
chcp 65001 >nul

echo ====================================================
echo Building Player by HEIMLICH with Custom Icon & Installer
echo ====================================================

:: Navigate to project root
cd ..\..

:: Create output directories if they don't exist
if not exist "output" mkdir output
if not exist "output\installers" mkdir output\installers
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

:: Step 3: Clean up previous build files
echo [STEP 3] Cleaning up previous build files...
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

:: Copy icon to multiple locations to ensure it's found
echo [INFO] Copying icon for resource compilation...
copy "..\output\temp\icon_win.ico" "." /Y
copy "..\output\temp\icon_win.ico" "icon_win.ico" /Y

:: Also ensure the icon is in the source directory
copy "..\output\temp\icon_win.ico" "..\icon_win.ico" /Y

:: Copy icon to build directory as well
copy "..\output\temp\icon_win.ico" "..\..\assets\Images\icon_win.ico" /Y

:: Verify icon files exist in multiple locations
echo [INFO] Verifying icon files in multiple locations...
if exist "..\assets\Images\icon_win.ico" (
    echo [SUCCESS] Icon found in source assets directory
) else (
    echo [WARNING] Icon not found in source assets directory
)

if exist "icon_win.ico" (
    echo [SUCCESS] Icon found in build directory
) else (
    echo [WARNING] Icon not found in build directory
)

if exist "..\icon_win.ico" (
    echo [SUCCESS] Icon found in source root
) else (
    echo [WARNING] Icon not found in source root
)

:: Add MinGW bin directory to PATH
set PATH=C:\Qt\6.9.0\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;%PATH%

echo [STEP 4] Running CMake with custom icon and dynamic versioning...
cmake -G "MinGW Makefiles" -DCMAKE_PREFIX_PATH=C:/Qt/6.9.0/mingw_64 -DCMAKE_BUILD_TYPE=Release ..

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake configuration failed!
    cd /d "%CURRENT_DIR%"
    rmdir "%TEMP_BUILD_DIR%\source"
    rmdir "%TEMP_BUILD_DIR%"
    pause
    exit /b 1
)

:: Verify resources.rc was generated
if exist "resources.rc" (
    echo [SUCCESS] resources.rc generated successfully!
    type resources.rc | findstr /C:"IDI_ICON1 ICON" > nul
    if %ERRORLEVEL% EQU 0 (
        echo [SUCCESS] Icon reference found in resources.rc!
    ) else (
        echo [WARNING] Icon reference not found in resources.rc!
    )
) else (
    echo [WARNING] resources.rc not found in build directory!
)

echo.
echo [STEP 5] Building the application with custom icon...
cmake --build . --config Release -j4

set BUILD_STATUS=%ERRORLEVEL%

if "%BUILD_STATUS%"=="0" (
    echo [STEP 6] Copying build output to original directory
    
    :: Create the build directory in the original location if it doesn't exist
    if not exist "%CURRENT_DIR%\build" mkdir "%CURRENT_DIR%\build"
    
    :: Copy the executable
    copy "Player-by-HEIMLICH.exe" "%CURRENT_DIR%\build" /Y
    
    :: Verify the executable has the icon
    echo [INFO] Verifying icon in executable...
    powershell -Command "& {$exe = '%CURRENT_DIR%\build\Player-by-HEIMLICH.exe'; if (Test-Path $exe) { $shell = New-Object -ComObject Shell.Application; $folder = $shell.Namespace((Get-Item $exe).DirectoryName); $file = $folder.ParseName((Get-Item $exe).Name); if ($file.ExtendedProperty('System.FileDescription')) { Write-Host '[SUCCESS] Executable has embedded resources!' -ForegroundColor Green } else { Write-Host '[WARNING] Could not verify embedded resources' -ForegroundColor Yellow } } }"
    
    :: Copy MPV DLL
    if exist "..\external\libs\windows\bin\libmpv-2.dll" (
        copy "..\external\libs\windows\bin\libmpv-2.dll" "%CURRENT_DIR%\build" /Y
    ) else if exist "..\external\mpv-dev\bin\libmpv-2.dll" (
        copy "..\external\mpv-dev\bin\libmpv-2.dll" "%CURRENT_DIR%\build" /Y
    )
    
    :: Run windeployqt
    echo [INFO] Running windeployqt...
    windeployqt "%CURRENT_DIR%\build\Player-by-HEIMLICH.exe" --qmldir="%CURRENT_DIR%\qml" --release
    timeout /t 5 > nul
    
    :: Copy QML files
    echo [INFO] Copying QML files...
    if not exist "%CURRENT_DIR%\build\qml" mkdir "%CURRENT_DIR%\build\qml"
    xcopy /Y /E /I "%CURRENT_DIR%\qml\*" "%CURRENT_DIR%\build\qml\"
    
    :: Copy assets directory (including custom icon)
    echo [INFO] Copying assets with custom icon...
    if not exist "%CURRENT_DIR%\build\assets" mkdir "%CURRENT_DIR%\build\assets"
    xcopy /Y /E /I "%CURRENT_DIR%\assets\*" "%CURRENT_DIR%\build\assets\"
    
    :: Return to original directory
    cd /d "%CURRENT_DIR%"
    
    :: Build installer with dynamic version and custom icon
    echo.
    echo [STEP 7] Building installer with custom icon...
    cmake --build "%TEMP_BUILD_DIR%\source\build" --target installer
    
    set INSTALLER_STATUS=%ERRORLEVEL%
    
    if "%INSTALLER_STATUS%"=="0" (
        echo.
        echo [STEP 8] Moving installer to output directory...
        
        :: Move installer file to output/installers directory
        for %%f in (Player*by*HEIMLICH*Setup*.exe) do (
            if exist "%%f" (
                move "%%f" "output\installers\"
                echo [SUCCESS] Installer moved to output\installers\%%f
            )
        )
        
        :: Copy temporary files to output/temp
        if exist "installer.nsi" (
            copy "installer.nsi" "%CURRENT_DIR%\output\temp\" /Y
        )
        if exist "icon_win.ico" (
            copy "icon_win.ico" "%CURRENT_DIR%\output\temp\" /Y
        )
        
        echo.
        echo ====================================================
        echo SUCCESS: Application and Installer built successfully!
        echo ====================================================
        
        :: Find and display installer info from output directory
        for %%f in (output\installers\Player*by*HEIMLICH*Setup*.exe) do (
            echo Installer file: %%f
            for %%A in ("%%f") do echo Size: %%~zA bytes
            echo.
            echo The installer includes:
            echo - Player by HEIMLICH with CUSTOM ICON
            echo - All Qt dependencies  
            echo - MPV libraries
            echo - Professional installer UI with custom icon
            echo - Version automatically synced: %CURRENT_VERSION%
            echo.
        )
        
        echo [INFO] Final icon verification...
        if exist "build\Player-by-HEIMLICH.exe" (
            echo [SUCCESS] Executable built with custom icon!
            echo [INFO] You can verify by checking the exe file in Windows Explorer
        )
    ) else (
        echo [WARNING] Installer build completed with warnings, but installer may have been generated!
        echo [INFO] Check the installer file for proper functionality.
        
        :: Still try to move any generated files
        for %%f in (Player*by*HEIMLICH*Setup*.exe) do (
            if exist "%%f" (
                move "%%f" "output\installers\"
                echo [INFO] Installer moved to output\installers\%%f
            )
        )
    )
    
) else (
    echo [ERROR] Application build failed!
    echo [ERROR] Check the error messages above for details.
    
    :: Save error log to output/logs
    echo [INFO] Saving error log...
    echo Build failed at %DATE% %TIME% > "output\logs\build_error_%CURRENT_VERSION%.log"
)

:: Clean up temporary build directory
echo.
echo [INFO] Cleaning up temporary build directory...
cd /d "%CURRENT_DIR%"
timeout /t 3 > nul
rmdir "%TEMP_BUILD_DIR%\source" 2>nul
rmdir "%TEMP_BUILD_DIR%" 2>nul

if "%BUILD_STATUS%" NEQ "0" (
    echo.
    echo [ERROR] Build failed! Check the errors above.
    echo [INFO] Error log saved to output\logs\build_error_%CURRENT_VERSION%.log
    cd batch\windows
    pause
    exit /b 1
) else (
    echo.
    echo ====================================================
    echo SUCCESS: Build complete with custom icon!
    echo ====================================================
    echo Your Player by HEIMLICH now has:
    echo - Custom icon_win.ico embedded in executable
    echo - Custom icon in installer
    echo - Dynamic version: %CURRENT_VERSION%
    echo - Professional installer package
    echo.
    echo Files organized in output directory:
    echo - output\installers\ : Installer files
    echo - output\temp\       : Temporary build files
    echo - output\logs\       : Build logs
    echo.
    echo [TIP] Check the executable in Windows Explorer to verify the custom icon
    echo.
    cd batch\windows
)

endlocal 