# Linux 스크립트

Linux용 Player by HEIMLICH 개발 및 실행을 위한 스크립트들입니다.

## 파일 목록

### 앱 실행 스크립트
- **`run-app.sh`** - 일반 실행 (백그라운드)
- **`run-app-debug.sh`** - 디버그 모드 실행 (콘솔 출력 표시)

### 빌드 스크립트
- **`build-app.sh`** - 앱 빌드 (CMake + make)

### 설정 스크립트
- **`setup-mpv.sh`** - MPV 라이브러리 설치 및 설정 (패키지 매니저 사용)

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

- Linux (Ubuntu 20.04+, Fedora 35+, Arch Linux 등)
- Qt 6.x
- CMake
- C++ 컴파일러 (GCC/Clang)
- MPV 개발 라이브러리

## 배포별 설치 명령어

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install qt6-base-dev qt6-qml-dev cmake build-essential libmpv-dev mpv
```

### Fedora
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel cmake gcc-c++ mpv-libs-devel mpv
```

### Arch Linux
```bash
sudo pacman -S qt6-base qt6-declarative cmake gcc mpv
```

### openSUSE
```bash
sudo zypper install qt6-base-devel qt6-declarative-devel cmake gcc-c++ libmpv-devel mpv
```

## 자동 설정

setup-mpv.sh 스크립트가 자동으로 배포판을 감지하고 적절한 패키지를 설치합니다:

```bash
./setup-mpv.sh
```

## 주의사항

- 모든 스크립트는 `batch/linux` 폴더에서 실행됩니다
- 실행 권한이 필요합니다: `chmod +x *.sh`
- 프로젝트 루트로 자동 이동 후 작업을 수행합니다
- 상대 경로 `../../`를 사용하여 프로젝트 루트에 접근합니다
- 시스템 MPV 라이브러리를 우선 사용합니다

## 파일 구조

```
batch/linux/
├── run-app.sh          # 일반 실행
├── run-app-debug.sh    # 디버그 실행
├── build-app.sh        # 앱 빌드
├── setup-mpv.sh        # MPV 설정
└── README.md           # 이 파일
```

## 문제 해결

### Qt가 찾아지지 않는 경우
```bash
# Qt 설치 확인
qmake --version

# 환경변수 설정 (필요한 경우)
export Qt6_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6
```

### MPV 라이브러리 문제
```bash
# MPV 개발 패키지 확인
dpkg -l | grep mpv  # Ubuntu/Debian
rpm -qa | grep mpv  # Fedora
pacman -Q | grep mpv  # Arch

# 재설치
./setup-mpv.sh
```

### 권한 문제
```bash
# 스크립트 실행 권한 부여
chmod +x *.sh

# sudo 없이 실행하되, setup-mpv.sh는 관리자 권한 필요
```

## AppImage 생성 (옵션)

Linux에서 포터블 AppImage를 만들려면:

```bash
# AppImageTool 설치 후
./build-app.sh
# AppImage 생성 스크립트 추가 예정
``` 