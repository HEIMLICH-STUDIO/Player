@echo off

echo ===================================================
echo AUTOMATIC MPV SETUP FOR HYPER-PLAYER
echo ===================================================

:: Create directories
mkdir external\mpv-dev\include 2>nul
mkdir external\mpv-dev\lib 2>nul
mkdir external\mpv-dev\bin 2>nul

:: Copy header files
if exist "external\mpv\include\mpv\*.h" (
    echo Copying header files...
    xcopy "external\mpv\include\mpv\*.h" "external\mpv-dev\include\" /Y /Q
    echo Header files copied successfully.
    echo.
)

:: Download direct from mpv-player
echo Downloading MPV development files...
set MPV_FILE=mpv-dev.7z

:: Try wget if available
where wget >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    wget -O %MPV_FILE% "https://github.com/shinchiro/mpv-winbuild-cmake/releases/download/20240413/mpv-dev-x86_64-20240413-git-aa4f274.7z"
) else (
    :: Fall back to PowerShell if wget not available
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/shinchiro/mpv-winbuild-cmake/releases/download/20240413/mpv-dev-x86_64-20240413-git-aa4f274.7z', '%MPV_FILE%')"
)

:: Check if the file was downloaded
if not exist "%MPV_FILE%" (
    echo Download failed.
    goto :manual_download
)

:: Check file size
for %%A in ("%MPV_FILE%") do set FILE_SIZE=%%~zA
if %FILE_SIZE% LSS 1000000 (
    echo Downloaded file is too small. Not a valid MPV archive.
    goto :manual_download
)

echo Download completed successfully.
echo.

:: Find 7-Zip
if exist "C:\Program Files\7-Zip\7z.exe" (
    set SEVENZIP="C:\Program Files\7-Zip\7z.exe"
) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set SEVENZIP="C:\Program Files (x86)\7-Zip\7z.exe"
) else (
    echo 7-Zip is not installed.
    goto :manual_download
)

:: Extract files
echo Extracting MPV files...
if exist tmp rmdir /s /q tmp
mkdir tmp

%SEVENZIP% x "%MPV_FILE%" -otmp -y
if %ERRORLEVEL% NEQ 0 (
    echo Extraction failed.
    goto :manual_download
)

:: Copy files
echo Copying files...

:: Copy DLL.A files
if exist "tmp\*.dll.a" (
    xcopy "tmp\*.dll.a" "external\mpv-dev\lib\" /Y /Q
    echo Library files copied.
) else (
    echo Cannot find library files (*.dll.a).
    goto :manual_download
)

:: Copy DLL files
if exist "tmp\*.dll" (
    xcopy "tmp\*.dll" "external\mpv-dev\bin\" /Y /Q
    echo DLL files copied.
) else (
    echo Cannot find DLL files.
    goto :manual_download
)

:: Cleanup
echo Cleaning up temporary files...
rmdir /s /q tmp
del "%MPV_FILE%"

:: Verify installation
if exist "external\mpv-dev\bin\libmpv-2.dll" (
    if exist "external\mpv-dev\lib\mpv.dll.a" (
        echo.
        echo ===================================================
        echo MPV development libraries installed successfully!
        echo ===================================================
        echo.
        echo You can now build HYPER-PLAYER.
        echo Use these commands to build:
        echo.
        echo mkdir build
        echo cd build
        echo cmake ..
        echo cmake --build .
        echo.
        goto :end
    )
)

echo MPV files were not installed correctly.

:manual_download
echo.
echo ===================================================
echo MANUAL DOWNLOAD REQUIRED
echo ===================================================
echo.
echo Automatic download failed. Please download manually from:
echo.
echo 1. GitHub: https://github.com/mpv-player/mpv/releases/tag/v0.40.0
echo 2. SourceForge: https://sourceforge.net/projects/mpv-player-windows/files/libmpv/
echo.
echo After downloading a mpv-dev-x86_64-*.7z file:
echo - Copy *.dll.a files to external\mpv-dev\lib folder
echo - Copy *.dll files to external\mpv-dev\bin folder
echo.
echo Then run build.bat to build your project.

:end
echo.
pause 