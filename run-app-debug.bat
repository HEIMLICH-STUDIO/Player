@echo off
echo Checking if executable exists...
if not exist "build\HYPER-PLAYER.exe" (
    echo HYPER-PLAYER.exe not found in build directory!
    pause
    exit /b 1
)

echo Making sure the MPV DLL is copied...
if exist "external\libs\windows\bin\libmpv-2.dll" (
    if not exist "build\libmpv-2.dll" (
        echo Copying libmpv-2.dll to build directory...
        copy "external\libs\windows\bin\libmpv-2.dll" "build\" /Y
    ) else (
        echo libmpv-2.dll already exists in build directory.
    )
) else (
    echo WARNING: libmpv-2.dll not found in external\libs\windows\bin
)

echo Starting HYPER-PLAYER in console mode...
cd build
HYPER-PLAYER.exe

echo Application exited with code %ERRORLEVEL%
pause 