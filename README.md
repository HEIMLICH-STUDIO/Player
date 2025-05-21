# HYPER-PLAYER

A cross-platform media player built with Qt, QML, and libmpv. Supports high-end codecs with hardware acceleration and features a beautiful, modern design.

## Features

- High-performance video playback via libmpv
- Hardware acceleration support through mpv's hwdec auto
- Beautiful, modern UI designed with QML
- Cross-platform support (Windows, macOS, Linux)
- Media controls with keyboard shortcuts
- Custom-styled volume and progress sliders
- Dark/light theme support
- Fullscreen mode

## Dependencies

- Qt 6.0 or higher (required)
- libmpv 0.32.0 or higher (optional, but needed for media playback)
- CMake 3.16 or higher (required)
- 7-Zip (required for automated MPV installation on Windows)

## Installation Instructions

### Windows

#### Option 1: Automated Setup (Recommended)

1. Install [Qt 6](https://www.qt.io/download) (6.2 or later recommended)
2. Install [CMake](https://cmake.org/download/) (3.16 or later)
3. Install [Visual Studio](https://visualstudio.microsoft.com/downloads/) with C++ workload or [MinGW](https://winlibs.com/)
4. Install [7-Zip](https://www.7-zip.org/download.html)
5. Run the MPV installation script:
   ```
   # Using batch script
   download_mpv.bat
   
   # OR using PowerShell
   powershell -ExecutionPolicy Bypass -File download_mpv.ps1
   ```
6. Build the application:
   ```
   build.bat
   ```

#### Option 2: Manual MPV Installation

If the automated process doesn't work:
1. Download MPV development files from [sourceforge](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/)
2. Extract the 7z archive
3. Create the following directory structure:
   ```
   external/mpv/include/   <- Place header files here (*.h)
   external/mpv/lib/       <- Place library files here (*.dll.a)
   external/mpv/bin/       <- Place DLL files here (*.dll)
   ```
4. Build the application with `build.bat`

### macOS

1. Install Qt 6:
   ```
   brew install qt@6
   ```
2. Install mpv:
   ```
   brew install mpv
   ```
3. Build manually:
   ```
   mkdir build && cd build
   cmake ..
   cmake --build .
   ```

### Linux (Ubuntu/Debian)

1. Install Qt 6:
   ```
   sudo apt install qt6-base-dev qt6-declarative-dev
   ```
2. Install mpv:
   ```
   sudo apt install libmpv-dev
   ```
3. Build:
   ```
   mkdir build && cd build
   cmake ..
   cmake --build .
   ```

## Build Options

### Building Without MPV

The application can be built without MPV support (UI-only mode):
```
cmake .. -DMPV_FOUND=OFF
```

### Directory Structure

After running the MPV installation script, your project should contain:
```
external/
  mpv/
    include/     <- MPV header files
    lib/         <- Library files (.dll.a)
    bin/         <- DLL files (.dll)
```

## MPV Installation Troubleshooting

If you encounter issues with MPV installation:

1. Make sure 7-Zip is installed and in your PATH
2. Check if the download URL in the script is still valid
3. If the download fails, try downloading manually from [sourceforge](https://sourceforge.net/projects/mpv-player-windows/files/libmpv/)
4. Look for the file named "mpv-dev-x86_64-*.7z" and extract it manually
5. Copy files to the appropriate directories as described in "Option 2: Manual MPV Installation"

## Usage

### Keyboard Shortcuts

- Space: Play/Pause
- F: Toggle Fullscreen
- Escape: Exit Fullscreen

### Mouse Controls

- Double-click: Toggle Fullscreen
- Click and drag on progress bar: Seek
- Click and drag on volume slider: Change volume

## 개선 및 추가 기능 제안

다음과 같은 기능을 고려해 볼 수 있습니다.

- **재생 목록 관리**: 여러 파일을 연속 재생할 수 있는 플레이리스트 기능
- **자막 로딩/선택**: 외부 자막 파일을 열고 동적으로 전환하는 기능
- **스크린샷 및 썸네일 생성**: 현재 프레임을 이미지로 저장하거나 썸네일을 표시
- **영상/음성 필터**: 색상 보정, 속도 조절 등 다양한 필터 적용 옵션
- **다국어 UI 지원**: 한국어 외 다른 언어 번역 및 설정 화면 제공

리팩토링 측면에서는 다음을 검토해 보세요.

- QML 컴포넌트 분리 및 모듈화로 코드 가독성 향상
- `MpvObject`와 `TimelineSync`의 책임 분리 및 테스트 코드 추가
- 설정 저장/불러오기 로직을 별도 클래스로 구현
- 예외 처리와 로깅 규칙을 통일하여 안정성 강화

## License

This project is licensed under the MIT License - see the LICENSE file for details. 