# 🔄 MPV → FFmpeg 전환 계획

## 📁 새로운 폴더 구조

```
Player-FFmpeg/
├── src/                          # 핵심 소스 코드
│   ├── core/                     # FFmpeg 핵심 기능
│   │   ├── ffmpeg_player.h       # 메인 플레이어 클래스
│   │   ├── ffmpeg_player.cpp
│   │   ├── decoder.h             # 디코더 관리
│   │   ├── decoder.cpp
│   │   ├── renderer.h            # 렌더링 엔진
│   │   └── renderer.cpp
│   ├── gui/                      # Qt GUI 관련
│   │   ├── main_window.h         # 메인 윈도우
│   │   ├── main_window.cpp
│   │   ├── video_widget.h        # 비디오 표시 위젯
│   │   ├── video_widget.cpp
│   │   ├── controls.h            # 플레이어 컨트롤
│   │   └── controls.cpp
│   ├── utils/                    # 유틸리티
│   │   ├── logger.h              # 로깅 시스템
│   │   ├── logger.cpp
│   │   ├── config.h              # 설정 관리
│   │   └── config.cpp
│   └── main.cpp                  # 진입점
├── resources/                    # 리소스 파일
│   ├── icons/                    # 아이콘들
│   ├── styles/                   # QSS 스타일
│   └── translations/             # 다국어 지원
├── external/                     # 외부 라이브러리
│   └── ffmpeg/                   # FFmpeg 라이브러리
│       ├── include/              # 헤더 파일
│       ├── lib/                  # 라이브러리 파일
│       └── bin/                  # DLL 파일 (Windows)
├── build/                        # 빌드 출력
├── docs/                         # 문서
├── tests/                        # 테스트 코드
├── CMakeLists.txt               # CMake 설정
├── README.md                    # 프로젝트 설명
└── .gitignore                   # Git 무시 파일
```

## 🗑️ 제거할 파일/폴더

### MPV 관련 (완전 제거)
- `MPV_LIBRARY/` - 전체 폴더
- `src/mpvobject.h` - MPV 객체
- `src/mpvobject.cpp`
- `src/timelinesync.h` - MPV 타임라인
- `src/timelinesync.cpp`

### QML 관련 (유지)
- ✅ `qml/` - QML 파일들 **유지**
- ✅ `qml.qrc` - QML 리소스 **유지**
- ✅ 기존 UI 디자인 **그대로 사용**

### 불필요한 빌드 파일
- `build/` - 기존 빌드 출력
- `output/` - 기존 출력
- `logs/` - 기존 로그
- `batch/` - 배치 스크립트들
- `backups/` - 백업 파일들

### 플랫폼별 (Windows만 남기고 제거)
- `macos/` - macOS 관련
- `vcpkg/` - vcpkg 관련 (FFmpeg 직접 사용)

## 🔧 새로운 기술 스택

### 기존 → 새로운
- **MPV** → **FFmpeg** (직접 사용)
- **QML UI** → **QML UI** (그대로 유지)
- **mpvobject** → **ffmpegobject** (백엔드만 교체)
- **복잡한 빌드** → **단순한 CMake**

## 📋 전환 단계

1. **정리 단계** - 불필요한 파일 제거
2. **구조 생성** - 새로운 폴더 구조 생성
3. **FFmpeg 통합** - FFmpeg 라이브러리 설정
4. **핵심 기능** - 플레이어 엔진 구현
5. **GUI 구현** - Qt Widgets 기반 UI
6. **테스트** - ProRes 파일 재생 테스트

## 🎯 목표 기능

### 핵심 기능
- ✅ ProRes 완전 지원 (인코딩/디코딩)
- ✅ 고성능 하드웨어 가속
- ✅ 프레임 단위 정밀 제어
- ✅ 실시간 재생

### 고급 기능
- 🔄 멀티스레드 디코딩
- 🔄 GPU 가속 렌더링
- 🔄 프로페셔널 컨트롤
- 🔄 메타데이터 표시

## ⚡ 예상 장점

1. **성능 향상** - FFmpeg 직접 제어로 최적화
2. **ProRes 특화** - Apple ProRes 완벽 지원
3. **단순한 구조** - 유지보수 용이
4. **빠른 개발** - Qt Widgets의 안정성 