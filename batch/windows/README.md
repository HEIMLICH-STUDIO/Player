r 

# Windows 배치 스크립트

Windows용 Player by HEIMLICH (FFmpeg 엔진) 개발 및 실행을 위한 배치 스크립트들입니다.

## 파일 목록

### 앱 실행 스크립트
- **`run-app-ffmpeg.bat`** - FFmpeg 엔진으로 일반 실행 ⭐ **NEW**
- **`run-app.bat`** - 레거시 실행 스크립트 (더 이상 권장하지 않음)
- **`run-app-debug.bat`** - 디버그 모드 실행 (콘솔 출력 표시)
- **`run-debug-console.bat`** - 별도 콘솔 창에서 디버그 실행

### 빌드 스크립트
- **`build-ffmpeg.bat`** - FFmpeg 전용 빌드 스크립트 ⭐ **NEW**
- **`build-with-installer.bat`** - 완전한 빌드 + 인스톨러 생성 (레거시)

### 설정 및 유틸리티
- **`setup-mpv.bat`** - MPV 라이브러리 다운로드 및 설정 (더 이상 필요 없음)
- **`extract-mpv.bat`** - 수동으로 다운로드한 MPV 아카이브 추출 (더 이상 필요 없음)
- **`qt-update.bat`** - Qt 설치 상태 및 환경 확인

## 사용 방법

### 처음 설정할 때 (FFmpeg 엔진) ⭐ **권장**
1. `qt-update.bat` 실행 - Qt 환경 확인
2. FFmpeg 설치 (아래 방법 중 하나):
   - **vcpkg**: `vcpkg install ffmpeg`
   - **MSYS2**: `pacman -S mingw-w64-x86_64-ffmpeg`
   - **수동**: https://www.gyan.dev/ffmpeg/builds/ 에서 다운로드
3. `build-ffmpeg.bat` 실행 - FFmpeg 빌드
4. `run-app-ffmpeg.bat` 실행 - 앱 실행

### 개발 중
- `run-app-ffmpeg.bat` - FFmpeg 엔진으로 앱 실행
- `run-app-debug.bat` - 디버그 모드로 앱 테스트  
- `run-debug-console.bat` - 콘솔 출력 확인하며 테스트

### 배포용 빌드
- `build-ffmpeg.bat` - FFmpeg 전용 빌드
- `build-with-installer.bat` - 인스톨러 포함 빌드 (레거시)

## 요구사항

### FFmpeg 엔진 (권장)
- Windows 10/11
- Qt 6.9.0 (MinGW 64-bit)
- CMake
- **FFmpeg 라이브러리** (vcpkg, MSYS2, 또는 수동 설치)
- PowerShell (아이콘 변환용)

### 레거시 MPV 엔진 (더 이상 권장하지 않음)
- Windows 10/11
- Qt 6.9.0 (MinGW 64-bit)
- CMake
- 7-Zip (MPV 추출용)
- PowerShell (아이콘 변환용)

## 주의사항

- 모든 스크립트는 `batch/windows` 폴더에서 실행됩니다
- 프로젝트 루트로 자동 이동 후 작업을 수행합니다
- 상대 경로 `../../`를 사용하여 프로젝트 루트에 접근합니다

## FFmpeg 엔진의 장점

✅ **성능**: 더 빠른 비디오 디코딩 및 렌더링  
✅ **호환성**: 더 넓은 비디오 포맷 지원 (MP4, MKV, AVI, MOV, WebM, M4V, TS, MTS, M2TS)  
✅ **안정성**: 업계 표준 라이브러리로 더 안정적  
✅ **하드웨어 가속**: 최신 하드웨어 가속 기능 지원  
✅ **유지보수**: 활발한 개발 및 지원  

## 파일 구조

```
batch/windows/
├── run-app-ffmpeg.bat         # FFmpeg 엔진 실행 ⭐ NEW
├── run-app.bat                # 레거시 실행
├── run-app-debug.bat          # 디버그 실행  
├── run-debug-console.bat      # 콘솔 디버그
├── build-ffmpeg.bat           # FFmpeg 빌드 ⭐ NEW
├── build-with-installer.bat   # 인스톨러 빌드 (레거시)
├── setup-mpv.bat             # MPV 설정 (사용 중단)
├── extract-mpv.bat           # MPV 추출 (사용 중단)
├── qt-update.bat             # Qt 환경 확인
└── README.md                 # 이 파일
``` 