r 

# Windows 배치 스크립트

Windows용 Player by HEIMLICH 개발 및 실행을 위한 배치 스크립트들입니다.

## 파일 목록

### 앱 실행 스크립트
- **`run-app.bat`** - 일반 실행 (백그라운드)
- **`run-app-debug.bat`** - 디버그 모드 실행 (콘솔 출력 표시)
- **`run-debug-console.bat`** - 별도 콘솔 창에서 디버그 실행

### 빌드 스크립트
- **`build-with-installer.bat`** - 완전한 빌드 + 인스톨러 생성
  - 아이콘 변환, 빌드, 패키징, 인스톨러 생성까지 모두 포함

### 설정 및 유틸리티
- **`setup-mpv.bat`** - MPV 라이브러리 다운로드 및 설정
- **`extract-mpv.bat`** - 수동으로 다운로드한 MPV 아카이브 추출
- **`qt-update.bat`** - Qt 설치 상태 및 환경 확인

## 사용 방법

### 처음 설정할 때
1. `setup-mpv.bat` 실행 - MPV 라이브러리 다운로드
2. `qt-update.bat` 실행 - Qt 환경 확인
3. `build-with-installer.bat` 실행 - 첫 빌드

### 개발 중
- `run-app-debug.bat` - 디버그 모드로 앱 테스트
- `run-debug-console.bat` - 콘솔 출력 확인하며 테스트

### 배포용 빌드
- `build-with-installer.bat` - 완전한 빌드 및 인스톨러 생성

## 요구사항

- Windows 10/11
- Qt 6.9.0 (MinGW 64-bit)
- CMake
- 7-Zip (MPV 추출용)
- PowerShell (아이콘 변환용)

## 주의사항

- 모든 스크립트는 `batch/windows` 폴더에서 실행됩니다
- 프로젝트 루트로 자동 이동 후 작업을 수행합니다
- 상대 경로 `../../`를 사용하여 프로젝트 루트에 접근합니다

## 파일 구조

```
batch/windows/
├── run-app.bat                  # 일반 실행
├── run-app-debug.bat           # 디버그 실행  
├── run-debug-console.bat       # 콘솔 디버그
├── build-with-installer.bat    # 빌드 + 인스톨러
├── setup-mpv.bat              # MPV 설정
├── extract-mpv.bat            # MPV 추출
├── qt-update.bat              # Qt 환경 확인
└── README.md                  # 이 파일
``` 