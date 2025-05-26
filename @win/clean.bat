@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Player by HEIMLICH® Clean Script
echo ========================================

:: Color settings
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Environment variables
set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build"

echo %BLUE%[INFO]%NC% Cleaning build artifacts...
echo %BLUE%[INFO]%NC% Project root: %PROJECT_ROOT%

:: Clean build directory
if exist "%BUILD_DIR%" (
    echo %BLUE%[INFO]%NC% Removing build directory: %BUILD_DIR%
    rmdir /s /q "%BUILD_DIR%" 2>nul
    if exist "%BUILD_DIR%" (
        echo %YELLOW%[WARNING]%NC% Some files in build directory could not be removed
        echo %BLUE%[INFO]%NC% This might be because the player is still running
    ) else (
        echo %GREEN%[OK]%NC% Build directory removed
    )
) else (
    echo %YELLOW%[INFO]%NC% Build directory does not exist
)

:: Clean CMake cache files
echo %BLUE%[INFO]%NC% Cleaning CMake cache files...
if exist "%PROJECT_ROOT%\CMakeCache.txt" (
    del "%PROJECT_ROOT%\CMakeCache.txt" 2>nul
    echo %GREEN%[OK]%NC% CMakeCache.txt removed
)

if exist "%PROJECT_ROOT%\CMakeFiles" (
    rmdir /s /q "%PROJECT_ROOT%\CMakeFiles" 2>nul
    echo %GREEN%[OK]%NC% CMakeFiles directory removed
)

:: Clean Qt generated files
echo %BLUE%[INFO]%NC% Cleaning Qt generated files...
for /r "%PROJECT_ROOT%" %%f in (*.qmlc) do (
    del "%%f" 2>nul
)

for /r "%PROJECT_ROOT%" %%f in (moc_*.cpp) do (
    del "%%f" 2>nul
)

for /r "%PROJECT_ROOT%" %%f in (ui_*.h) do (
    del "%%f" 2>nul
)

for /r "%PROJECT_ROOT%" %%f in (qrc_*.cpp) do (
    del "%%f" 2>nul
)

:: Clean temporary files
echo %BLUE%[INFO]%NC% Cleaning temporary files...
for /r "%PROJECT_ROOT%" %%f in (*.tmp) do (
    del "%%f" 2>nul
)

for /r "%PROJECT_ROOT%" %%f in (*.log) do (
    del "%%f" 2>nul
)

for /r "%PROJECT_ROOT%" %%f in (*~) do (
    del "%%f" 2>nul
)

:: Clean object files
echo %BLUE%[INFO]%NC% Cleaning object files...
for /r "%PROJECT_ROOT%" %%f in (*.o) do (
    del "%%f" 2>nul
)

for /r "%PROJECT_ROOT%" %%f in (*.obj) do (
    del "%%f" 2>nul
)

:: Clean backup files
echo %BLUE%[INFO]%NC% Cleaning backup files...
for /r "%PROJECT_ROOT%" %%f in (*.bak) do (
    del "%%f" 2>nul
)

for /r "%PROJECT_ROOT%" %%f in (*.orig) do (
    del "%%f" 2>nul
)

:: Optional: Clean FFmpeg installation (ask user)
set /p "clean_ffmpeg=Do you want to clean FFmpeg installation? (y/N): "
if /i "%clean_ffmpeg%"=="y" (
    echo %BLUE%[INFO]%NC% Cleaning FFmpeg installation...
    if exist "%PROJECT_ROOT%\external\ffmpeg" (
        rmdir /s /q "%PROJECT_ROOT%\external\ffmpeg" 2>nul
        echo %GREEN%[OK]%NC% FFmpeg installation removed
    ) else (
        echo %YELLOW%[INFO]%NC% FFmpeg installation not found
    )
)

echo.
echo %GREEN%[SUCCESS]%NC% Cleanup completed!
echo %BLUE%[INFO]%NC% You can now run build.bat to rebuild the project
pause 