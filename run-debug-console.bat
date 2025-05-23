@echo off
echo Checking if executable exists...
if not exist "build\Player-by-HEIMLICH.exe" (
    echo Player-by-HEIMLICH.exe not found in build directory!
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

echo Starting Player by HEIMLICH® with debug console...
cd build
start "Player by HEIMLICH® Debug Console" cmd /k Player-by-HEIMLICH.exe

echo Application should be running in a separate window now.
echo This console will remain open to capture any output.
echo Close this window after you're done testing. 