@echo off
echo ===================================================
echo MPV Library Extraction Tool
echo ===================================================

:: Navigate to project root
cd ..\..

:: Check if external directories exist
if not exist "external" mkdir external
if not exist "external\libs" mkdir external\libs
if not exist "external\libs\windows" mkdir external\libs\windows
if not exist "external\libs\windows\bin" mkdir external\libs\windows\bin
if not exist "external\libs\windows\lib" mkdir external\libs\windows\lib
if not exist "external\libs\windows\include" mkdir external\libs\windows\include

echo [INFO] Searching for MPV archives in current directory...

:: Look for MPV archive files
set MPV_ARCHIVE=
if exist "mpv-dev*.7z" (
    for %%f in (mpv-dev*.7z) do set MPV_ARCHIVE=%%f
    goto :found
)
if exist "mpv-dev*.zip" (
    for %%f in (mpv-dev*.zip) do set MPV_ARCHIVE=%%f
    goto :found
)
if exist "mpv*.7z" (
    for %%f in (mpv*.7z) do set MPV_ARCHIVE=%%f
    goto :found
)
if exist "mpv*.zip" (
    for %%f in (mpv*.zip) do set MPV_ARCHIVE=%%f
    goto :found
)

echo [ERROR] No MPV archive found!
echo Please download MPV development files from:
echo https://github.com/shinchiro/mpv-winbuild-cmake/releases
echo.
echo Expected file names:
echo - mpv-dev-x86_64-*.7z
echo - mpv-dev-*.zip
echo.
goto :end

:found
echo [SUCCESS] Found MPV archive: %MPV_ARCHIVE%

:: Check file size
for %%A in ("%MPV_ARCHIVE%") do set FILE_SIZE=%%~zA
if %FILE_SIZE% LSS 1000000 (
    echo [WARNING] Archive file seems too small (less than 1MB)
    echo Please verify the file was downloaded completely
)

echo File size: %FILE_SIZE% bytes

:: Find extraction tool
set EXTRACT_TOOL=
set EXTRACT_CMD=

:: Check for 7-Zip
if exist "C:\Program Files\7-Zip\7z.exe" (
    set EXTRACT_TOOL="C:\Program Files\7-Zip\7z.exe"
    set EXTRACT_CMD=%EXTRACT_TOOL% x "%MPV_ARCHIVE%" -otmp -y
    goto :extract
)
if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set EXTRACT_TOOL="C:\Program Files (x86)\7-Zip\7z.exe"
    set EXTRACT_CMD=%EXTRACT_TOOL% x "%MPV_ARCHIVE%" -otmp -y
    goto :extract
)

:: Check for WinRAR
if exist "C:\Program Files\WinRAR\WinRAR.exe" (
    set EXTRACT_TOOL="C:\Program Files\WinRAR\WinRAR.exe"
    set EXTRACT_CMD=%EXTRACT_TOOL% x "%MPV_ARCHIVE%" tmp\
    goto :extract
)
if exist "C:\Program Files (x86)\WinRAR\WinRAR.exe" (
    set EXTRACT_TOOL="C:\Program Files (x86)\WinRAR\WinRAR.exe"
    set EXTRACT_CMD=%EXTRACT_TOOL% x "%MPV_ARCHIVE%" tmp\
    goto :extract
)

:: Try PowerShell for ZIP files
if "%MPV_ARCHIVE:~-4%"==".zip" (
    echo [INFO] Using PowerShell to extract ZIP file...
    if exist tmp rmdir /s /q tmp
    mkdir tmp
    powershell -Command "Expand-Archive -Path '%MPV_ARCHIVE%' -DestinationPath 'tmp' -Force"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] PowerShell extraction failed!
        goto :end
    )
    goto :copy_files
)

echo [ERROR] No suitable extraction tool found!
echo Please install one of the following:
echo - 7-Zip (recommended): https://www.7-zip.org/
echo - WinRAR: https://www.win-rar.com/
echo.
goto :end

:extract
echo [INFO] Extracting %MPV_ARCHIVE% using %EXTRACT_TOOL%...

:: Clean up previous extraction
if exist tmp rmdir /s /q tmp
mkdir tmp

:: Extract the archive
%EXTRACT_CMD%

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Extraction failed!
    echo Command used: %EXTRACT_CMD%
    goto :end
)

:copy_files
echo [INFO] Copying files to external\libs\windows...

:: Copy DLL files
if exist "tmp\*.dll" (
    copy "tmp\*.dll" "external\libs\windows\bin\" /Y
    echo [SUCCESS] DLL files copied
) else (
    echo [WARNING] No DLL files found in archive
)

:: Copy library files (.dll.a, .lib)
if exist "tmp\*.dll.a" (
    copy "tmp\*.dll.a" "external\libs\windows\lib\" /Y
    echo [SUCCESS] Library (.dll.a) files copied
)
if exist "tmp\*.lib" (
    copy "tmp\*.lib" "external\libs\windows\lib\" /Y
    echo [SUCCESS] Library (.lib) files copied
)

:: Copy header files
if exist "tmp\include\mpv" (
    xcopy "tmp\include\mpv\*" "external\libs\windows\include\" /Y /S
    echo [SUCCESS] Header files copied
) else if exist "tmp\mpv" (
    xcopy "tmp\mpv\*" "external\libs\windows\include\" /Y /S
    echo [SUCCESS] Header files copied
) else (
    echo [WARNING] No header files found in archive
)

:: Verify extraction
echo.
echo [INFO] Verifying extracted files...

if exist "external\libs\windows\bin\libmpv-2.dll" (
    echo [SUCCESS] libmpv-2.dll found
    for %%A in ("external\libs\windows\bin\libmpv-2.dll") do echo Size: %%~zA bytes
) else (
    echo [WARNING] libmpv-2.dll not found
)

if exist "external\libs\windows\include\mpv" (
    echo [SUCCESS] MPV headers found
) else (
    echo [WARNING] MPV headers not found
)

:: Cleanup
echo.
echo [INFO] Cleaning up temporary files...
if exist tmp rmdir /s /q tmp

echo.
echo ===================================================
echo MPV extraction completed!
echo ===================================================
echo Files extracted to:
echo - DLLs: external\libs\windows\bin\
echo - Libraries: external\libs\windows\lib\
echo - Headers: external\libs\windows\include\
echo ===================================================

:end
cd batch\windows
pause 