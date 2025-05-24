@echo off

echo ===================================================
echo SETTING UP MPV FOR WINDOWS
echo ===================================================

:: Navigate to project root
cd ..\..

:: Create directories
mkdir external\libs\windows\include 2>nul
mkdir external\libs\windows\lib 2>nul
mkdir external\libs\windows\bin 2>nul

echo Downloading MPV development files...
set MPV_URL=https://github.com/shinchiro/mpv-winbuild-cmake/releases/download/20240413/mpv-dev-x86_64-20240413-git-aa4f274.7z
set MPV_FILE=mpv-dev.7z

:: Try PowerShell for download
powershell -Command "(New-Object Net.WebClient).DownloadFile('%MPV_URL%', '%MPV_FILE%')"

:: Check if the file was downloaded
if not exist "%MPV_FILE%" (
    echo Download failed. Please download manually from:
    echo %MPV_URL%
    echo and extract it to external\libs\windows directory.
    goto :end
)

:: Check file size
for %%A in ("%MPV_FILE%") do set FILE_SIZE=%%~zA
if %FILE_SIZE% LSS 1000000 (
    echo Downloaded file is too small. Please download manually.
    goto :end
)

echo Download completed successfully.

:: Find 7-Zip
set SEVENZIP=
if exist "C:\Program Files\7-Zip\7z.exe" (
    set SEVENZIP="C:\Program Files\7-Zip\7z.exe"
) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set SEVENZIP="C:\Program Files (x86)\7-Zip\7z.exe"
) else (
    echo 7-Zip is not installed. Please install 7-Zip or extract the file manually.
    goto :end
)

:: Extract files
echo Extracting MPV files...
if exist tmp rmdir /s /q tmp
mkdir tmp

%SEVENZIP% x "%MPV_FILE%" -otmp -y
if %ERRORLEVEL% NEQ 0 (
    echo Extraction failed.
    goto :end
)

:: Copy files
echo Copying files to external\libs\windows...

:: Copy header files
xcopy "tmp\include\mpv\*.h" "external\libs\windows\include\" /Y /Q
echo Header files copied.

:: Copy library files
xcopy "tmp\*.dll.a" "external\libs\windows\lib\" /Y /Q
echo Library files copied.

:: Copy DLL files
xcopy "tmp\*.dll" "external\libs\windows\bin\" /Y /Q
echo DLL files copied.

:: Cleanup
echo Cleaning up temporary files...
rmdir /s /q tmp
del "%MPV_FILE%"

echo.
echo ===================================================
echo MPV setup for Windows completed successfully!
echo ===================================================

:end
cd batch\windows
pause 