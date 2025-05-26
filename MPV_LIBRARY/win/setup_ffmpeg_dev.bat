@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   FFmpeg ProRes 개발 환경 설정
echo ========================================

:: 환경 변수 설정
set "MSYS2_ROOT=C:\msys64"
set "MINGW64_BIN=%MSYS2_ROOT%\mingw64\bin"
set "MINGW64_INCLUDE=%MSYS2_ROOT%\mingw64\include"
set "MINGW64_LIB=%MSYS2_ROOT%\mingw64\lib"

:: 개발 디렉토리 생성
set "DEV_DIR=%~dp0ffmpeg_player_dev"
if not exist "%DEV_DIR%" mkdir "%DEV_DIR%"
cd /d "%DEV_DIR%"

echo [INFO] FFmpeg 개발 라이브러리 확인 중...

:: FFmpeg 개발 헤더 확인
if not exist "%MINGW64_INCLUDE%\libavcodec\avcodec.h" (
    echo [ERROR] FFmpeg 개발 헤더가 없습니다. 설치 중...
    "%MSYS2_ROOT%\usr\bin\bash.exe" -lc "pacman -S --noconfirm mingw-w64-x86_64-ffmpeg"
) else (
    echo [OK] FFmpeg 개발 헤더 발견
)

:: ProRes 지원 확인
echo [INFO] ProRes 지원 확인 중...
"%MINGW64_BIN%\ffmpeg.exe" -codecs | findstr -i prores
if !errorlevel! equ 0 (
    echo [OK] ProRes 완전 지원 확인됨
) else (
    echo [WARNING] ProRes 지원 확인 실패
)

:: 개발 도구 확인
echo [INFO] 개발 도구 확인 중...
set "TOOLS_MISSING="

if not exist "%MINGW64_BIN%\gcc.exe" set "TOOLS_MISSING=!TOOLS_MISSING! gcc"
if not exist "%MINGW64_BIN%\g++.exe" set "TOOLS_MISSING=!TOOLS_MISSING! g++"
if not exist "%MINGW64_BIN%\make.exe" set "TOOLS_MISSING=!TOOLS_MISSING! make"
if not exist "%MINGW64_BIN%\pkg-config.exe" set "TOOLS_MISSING=!TOOLS_MISSING! pkg-config"

if not "!TOOLS_MISSING!"=="" (
    echo [INFO] 누락된 도구 설치 중: !TOOLS_MISSING!
    "%MSYS2_ROOT%\usr\bin\bash.exe" -lc "pacman -S --noconfirm mingw-w64-x86_64-toolchain mingw-w64-x86_64-pkg-config"
) else (
    echo [OK] 모든 개발 도구 확인됨
)

:: 샘플 프로젝트 생성
echo [INFO] 샘플 프로젝트 생성 중...

:: CMakeLists.txt 생성
echo cmake_minimum_required(VERSION 3.16) > CMakeLists.txt
echo project(FFmpegProResPlayer) >> CMakeLists.txt
echo. >> CMakeLists.txt
echo set(CMAKE_CXX_STANDARD 17) >> CMakeLists.txt
echo. >> CMakeLists.txt
echo # FFmpeg 라이브러리 찾기 >> CMakeLists.txt
echo find_package(PkgConfig REQUIRED) >> CMakeLists.txt
echo pkg_check_modules(FFMPEG REQUIRED libavformat libavcodec libavutil libswscale) >> CMakeLists.txt
echo. >> CMakeLists.txt
echo # 실행 파일 생성 >> CMakeLists.txt
echo add_executable(prores_player main.cpp) >> CMakeLists.txt
echo. >> CMakeLists.txt
echo # 라이브러리 링크 >> CMakeLists.txt
echo target_link_libraries(prores_player ${FFMPEG_LIBRARIES}) >> CMakeLists.txt
echo target_include_directories(prores_player PRIVATE ${FFMPEG_INCLUDE_DIRS}) >> CMakeLists.txt
echo target_compile_options(prores_player PRIVATE ${FFMPEG_CFLAGS_OTHER}) >> CMakeLists.txt

:: 환경 설정 스크립트 생성
echo @echo off > setup_env.bat
echo set "PATH=%MINGW64_BIN%;%%PATH%%" >> setup_env.bat
echo set "PKG_CONFIG_PATH=%MINGW64_LIB%\pkgconfig" >> setup_env.bat
echo echo FFmpeg 개발 환경이 설정되었습니다. >> setup_env.bat
echo echo. >> setup_env.bat
echo echo 사용 가능한 명령: >> setup_env.bat
echo echo   - gcc/g++: 컴파일러 >> setup_env.bat
echo echo   - pkg-config: 라이브러리 설정 >> setup_env.bat
echo echo   - ffmpeg: 미디어 처리 >> setup_env.bat
echo echo. >> setup_env.bat

echo.
echo ========================================
echo   설정 완료!
echo ========================================
echo.
echo 개발 디렉토리: %DEV_DIR%
echo.
echo 다음 단계:
echo 1. cd "%DEV_DIR%"
echo 2. setup_env.bat 실행
echo 3. 샘플 코드 작성 및 컴파일
echo.
echo ProRes 지원 확인:
"%MINGW64_BIN%\ffmpeg.exe" -encoders | findstr prores

pause 