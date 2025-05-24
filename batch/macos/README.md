# macOS 스크립트

macOS용 Player by HEIMLICH 개발 및 실행을 위한 스크립트들입니다.

## 파일 목록

### 앱 실행 스크립트
- **`run-app.sh`** - 일반 실행 (백그라운드)
- **`run-app-debug.sh`** - 디버그 모드 실행 (콘솔 출력 표시)

### 빌드 스크립트  
- **`build-app.sh`** - 앱 빌드 (CMake + make)

### 설정 스크립트
- **`setup-mpv.sh`** - MPV 라이브러리 설치 및 설정 (Homebrew 사용)

## 사용 방법

### 처음 설정할 때
1. `./setup-mpv.sh` 실행 - MPV 라이브러리 설치
2. `./build-app.sh` 실행 - 첫 빌드

### 개발 중
- `./run-app-debug.sh` - 디버그 모드로 앱 테스트
- `./run-app.sh` - 일반 모드로 앱 실행

### 새 빌드
- `./build-app.sh` - 전체 빌드

## 요구사항

- macOS 10.15 이상
- Xcode Command Line Tools
- Qt 6.x (Homebrew 또는 공식 설치)
- Homebrew
- CMake

## 설치 명령어

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 기본 요구사항 설치
brew install qt cmake

# MPV 설정 (스크립트가 자동으로 실행)
./setup-mpv.sh
```

## 주의사항

- 모든 스크립트는 `batch/macos` 폴더에서 실행됩니다
- 실행 권한이 필요합니다: `chmod +x *.sh`
- 프로젝트 루트로 자동 이동 후 작업을 수행합니다
- 상대 경로 `../../`를 사용하여 프로젝트 루트에 접근합니다

## 파일 구조

```
batch/macos/
├── run-app.sh          # 일반 실행
├── run-app-debug.sh    # 디버그 실행
├── build-app.sh        # 앱 빌드
├── setup-mpv.sh        # MPV 설정
└── README.md           # 이 파일
```

## 문제 해결

### Qt가 찾아지지 않는 경우
```bash
# Homebrew Qt 경로 확인
brew --prefix qt

# 환경변수 설정
export Qt6_DIR=$(brew --prefix qt)/lib/cmake/Qt6
```

### MPV 라이브러리 문제
```bash
# MPV 재설치
brew uninstall mpv
brew install mpv

# 스크립트 재실행
./setup-mpv.sh
``` 