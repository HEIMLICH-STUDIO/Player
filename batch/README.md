# Player by HEIMLICH - OS별 배치 스크립트

Player by HEIMLICH 프로젝트의 OS별 개발/빌드/실행 스크립트들을 정리한 폴더입니다.

## 폴더 구조

```
batch/
├── windows/        # Windows 배치 파일들 (.bat)
├── macos/          # macOS 셸 스크립트들 (.sh)  
├── linux/          # Linux 셸 스크립트들 (.sh)
└── README.md       # 이 파일
```

## OS별 빠른 시작

### 🪟 Windows
```cmd
cd batch\windows
setup-mpv.bat          # MPV 라이브러리 설치
qt-update.bat          # Qt 환경 확인
build-with-installer.bat # 빌드 + 인스톨러 생성
run-app-debug.bat      # 디버그 실행
```

### 🍎 macOS  
```bash
cd batch/macos
chmod +x *.sh         # 실행 권한 부여
./setup-mpv.sh        # MPV 라이브러리 설치
./build-app.sh        # 앱 빌드
./run-app-debug.sh    # 디버그 실행
```

### 🐧 Linux
```bash
cd batch/linux  
chmod +x *.sh         # 실행 권한 부여
./setup-mpv.sh        # MPV 라이브러리 설치
./build-app.sh        # 앱 빌드
./run-app-debug.sh    # 디버그 실행
```

## 주요 기능

### 🔧 설정 스크립트
- **MPV 라이브러리 자동 설치**: 각 OS에 맞는 방법으로 MPV 설치
- **환경 검증**: Qt, CMake, 컴파일러 등 개발 환경 확인

### 🏗️ 빌드 스크립트
- **크로스 플랫폼 빌드**: CMake 기반 빌드 시스템
- **의존성 자동 복사**: 라이브러리 및 리소스 파일 자동 배치
- **Windows 인스톨러**: NSIS 기반 설치 프로그램 생성

### 🚀 실행 스크립트
- **일반 실행**: 백그라운드에서 앱 실행
- **디버그 모드**: 콘솔 출력과 함께 실행
- **자동 라이브러리 복사**: 필요한 DLL/SO/DYLIB 자동 처리

## 공통 요구사항

| OS | Qt | CMake | 컴파일러 | MPV | 추가 도구 |
|----|----|----|----|----|----| 
| Windows | 6.9.0 MinGW | ✓ | MinGW 64-bit | 자동 다운로드 | 7-Zip, PowerShell |
| macOS | 6.x | ✓ | Clang (Xcode) | Homebrew | Homebrew |
| Linux | 6.x | ✓ | GCC/Clang | 패키지 매니저 | 패키지 매니저 |

## 경로 구조

모든 스크립트는 다음과 같은 상대 경로 구조를 사용합니다:

```
프로젝트 루트/
├── batch/
│   ├── windows/    ← 여기서 Windows 스크립트 실행
│   ├── macos/      ← 여기서 macOS 스크립트 실행
│   └── linux/      ← 여기서 Linux 스크립트 실행
├── build/          ← 빌드 결과물
├── external/       ← 외부 라이브러리 (MPV 등)
├── src/            ← 소스 코드
├── qml/            ← QML 파일들
└── assets/         ← 리소스 파일들
```

## 문제 해결

### 공통 문제
1. **권한 문제** (macOS/Linux): `chmod +x *.sh`로 실행 권한 부여
2. **Qt 경로 문제**: 환경변수 `Qt6_DIR` 설정
3. **MPV 라이브러리 문제**: 각 OS의 `setup-mpv` 스크립트 재실행

### OS별 상세 문제 해결
각 OS 폴더의 README.md 파일을 참조하세요:
- [Windows README](windows/README.md)
- [macOS README](macos/README.md)  
- [Linux README](linux/README.md)

## 개발 워크플로

### 새 개발자 설정
1. 해당 OS 폴더로 이동
2. `setup-mpv` 스크립트 실행
3. 환경 확인 스크립트 실행 (Windows의 경우 `qt-update.bat`)
4. 빌드 스크립트 실행
5. 디버그 실행으로 테스트

### 일반적인 개발 사이클
1. 코드 수정
2. 디버그 실행으로 빠른 테스트
3. 필요시 전체 빌드
4. 배포용 빌드 (Windows의 경우 인스톨러 포함)

## 기여하기

새로운 OS 지원이나 스크립트 개선을 위한 기여는 언제나 환영합니다:

1. 기존 스크립트 구조 따르기
2. 상대 경로 `../../` 사용하여 프로젝트 루트 접근  
3. 에러 처리 및 사용자 친화적 메시지 포함
4. 각 OS 폴더의 README.md 업데이트 