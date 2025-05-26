@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Player by HEIMLICH® Static Build
echo ========================================

:: Color settings
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Environment variables
set "MSYS2_PATH=C:\msys64\mingw64\bin"
set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build_static"

echo %BLUE%[INFO]%NC% Project root: %PROJECT_ROOT%
echo %BLUE%[INFO]%NC% Static build directory: %BUILD_DIR%

:: Check MSYS2 path
if not exist "%MSYS2_PATH%\gcc.exe" (
    echo %RED%[ERROR]%NC% MSYS2 MinGW64 is not installed.
    echo %YELLOW%[INFO]%NC% Please install MSYS2 and run the following commands:
    echo   pacman -S mingw-w64-x86_64-toolchain
    echo   pacman -S mingw-w64-x86_64-cmake
    echo   pacman -S mingw-w64-x86_64-qt6-static
    echo   pacman -S mingw-w64-x86_64-ffmpeg
    pause
    exit /b 1
)

:: Add MSYS2 to PATH
set "PATH=%MSYS2_PATH%;%PATH%"

:: Check compiler
echo %BLUE%[INFO]%NC% Checking compiler...
gcc --version >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%NC% GCC compiler not found.
    pause
    exit /b 1
)

:: Check FFmpeg
echo %BLUE%[INFO]%NC% Checking FFmpeg...
if not exist "%PROJECT_ROOT%\external\ffmpeg\include\libavformat\avformat.h" (
    echo %YELLOW%[WARNING]%NC% FFmpeg libraries not found. Installing...
    call "%~dp0setup_ffmpeg.bat"
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% FFmpeg installation failed
        pause
        exit /b 1
    )
)

:: Prepare build directory
echo %BLUE%[INFO]%NC% Preparing static build directory...
if exist "%BUILD_DIR%" (
    echo %YELLOW%[INFO]%NC% Cleaning existing build directory...
    rmdir /s /q "%BUILD_DIR%" 2>nul
)
mkdir "%BUILD_DIR%"

:: Configure CMake for static linking
echo %BLUE%[INFO]%NC% Configuring CMake for static linking...
cd /d "%BUILD_DIR%"

cmake .. -G "MinGW Makefiles" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" ^
    -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive" ^
    -DQt6_DIR="C:/msys64/mingw64/lib/cmake/Qt6" ^
    -DCMAKE_PREFIX_PATH="C:/msys64/mingw64"

if errorlevel 1 (
    echo %RED%[ERROR]%NC% CMake configuration failed
    pause
    exit /b 1
)

:: Build project
echo %BLUE%[INFO]%NC% Building project with static linking...
cmake --build . --parallel 4
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Build failed
    pause
    exit /b 1
)

:: Copy only essential DLLs that cannot be statically linked
echo %BLUE%[INFO]%NC% Copying essential DLLs...

:: Copy FFmpeg DLLs (these usually need to be dynamic)
copy "%PROJECT_ROOT%\external\ffmpeg\bin\*.dll" . >nul 2>&1

:: Copy only essential Qt6 DLLs if needed
if not exist "Qt6Core.dll" (
    echo %YELLOW%[INFO]%NC% Qt6 seems to be statically linked - good!
) else (
    echo %BLUE%[INFO]%NC% Copying Qt6 platform plugins...
    if not exist "platforms" mkdir "platforms"
    copy "C:\msys64\mingw64\share\qt6\plugins\platforms\qwindows.dll" "platforms\" >nul 2>&1
)

:: Check file size (static builds are usually larger)
echo %BLUE%[INFO]%NC% Checking executable size...
dir "Player-by-HEIMLICH.exe"

:: Test dependencies
echo %BLUE%[INFO]%NC% Analyzing dependencies...
objdump -p Player-by-HEIMLICH.exe | findstr "DLL Name:" > static_deps.txt
echo %BLUE%[INFO]%NC% Dependencies found:
type static_deps.txt
del static_deps.txt

:: Success message
echo.
echo %GREEN%[SUCCESS]%NC% Static build completed!
echo %BLUE%[INFO]%NC% Executable: %BUILD_DIR%\Player-by-HEIMLICH.exe
echo %YELLOW%[INFO]%NC% This build should have minimal DLL dependencies.
echo.

:: Ask to run
set /p "run=Do you want to run the static build? (y/N): "
if /i "%run%"=="y" (
    echo %BLUE%[INFO]%NC% Starting static player...
    start "" "Player-by-HEIMLICH.exe"
)

echo %BLUE%[INFO]%NC% Static build script completed
pause 