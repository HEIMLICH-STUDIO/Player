@echo off

echo ===================================================
echo MPV 파일 압축 해제 및 설치
echo ===================================================

:: 디렉토리 생성
mkdir external\libs\windows\include 2>nul
mkdir external\libs\windows\lib 2>nul
mkdir external\libs\windows\bin 2>nul

:: 압축 파일 찾기
set FOUND=0
for %%f in (mpv-dev-x86_64-*.7z) do (
    set MPV_FILE=%%f
    set FOUND=1
)

if %FOUND%==0 (
    echo MPV 개발 파일을 찾을 수 없습니다.
    echo mpv-dev-x86_64-*.7z 파일을 이 폴더에 다운로드하세요.
    goto :end
)

echo 파일 발견: %MPV_FILE%

:: 7-Zip 찾기
if exist "C:\Program Files\7-Zip\7z.exe" (
    set SEVENZIP="C:\Program Files\7-Zip\7z.exe"
) else if exist "C:\Program Files (x86)\7-Zip\7z.exe" (
    set SEVENZIP="C:\Program Files (x86)\7-Zip\7z.exe"
) else (
    echo 7-Zip을 찾을 수 없습니다. 7-Zip을 설치하세요.
    goto :end
)

:: 압축 해제
echo 압축 해제 중...
if exist tmp rmdir /s /q tmp
mkdir tmp

%SEVENZIP% x "%MPV_FILE%" -otmp -y
if %ERRORLEVEL% NEQ 0 (
    echo 압축 해제 실패.
    goto :end
)

:: 파일 복사
echo 파일 복사 중...

:: 헤더 파일 복사
echo 헤더 파일 복사 중...
xcopy "tmp\include\mpv\*.h" "external\libs\windows\include\" /Y /Q

:: 라이브러리 파일 복사
echo 라이브러리 파일 복사 중...
xcopy "tmp\*.dll.a" "external\libs\windows\lib\" /Y /Q

:: DLL 파일 복사
echo DLL 파일 복사 중...
xcopy "tmp\*.dll" "external\libs\windows\bin\" /Y /Q

:: 정리
echo 임시 파일 정리 중...
rmdir /s /q tmp

echo.
echo ===================================================
echo MPV 설치 완료!
echo ===================================================
echo.
echo 이제 다음 명령으로 프로젝트를 빌드할 수 있습니다:
echo.
echo   mkdir build
echo   cd build
echo   cmake ..
echo   cmake --build .

:end
pause 