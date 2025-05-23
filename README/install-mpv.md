# MPV 수동 설치 가이드

GitHub에서의 직접 다운로드가 되지 않으므로, 다음 수동 설치 방법을 사용하세요:

## 1. MPV 개발 파일 다운로드

다음 주소 중 하나를 사용하여 수동으로 다운로드하세요:

- [shinchiro의 빌드](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
  - `mpv-dev-x86_64-XXXXXXXX-git-XXXXXX.7z` 파일 다운로드

또는

- [libmpv GitHub 미러](https://github.com/btimby/libmpv/releases)

## 2. 파일 압축 해제 및 복사

1. 다운로드한 7z 파일을 압축 해제합니다.
2. 아래와 같이 파일을 복사합니다:
   - `include/mpv/*.h` 파일들 → `external\libs\windows\include\` 폴더로
   - `*.dll.a` 파일들 → `external\libs\windows\lib\` 폴더로
   - `*.dll` 파일들 → `external\libs\windows\bin\` 폴더로

## 3. 대체 방법: 7z 프로그램으로 압축 해제

7-Zip이 설치되어 있다면:

1. 다운로드한 .7z 파일에서 마우스 우클릭
2. 7-Zip → 여기에 압축 풀기
3. 압축 해제된 폴더에서:
   - `include/mpv` 폴더 내용을 → `external\libs\windows\include\` 폴더로
   - 모든 `.dll.a` 파일을 → `external\libs\windows\lib\` 폴더로
   - 모든 `.dll` 파일을 → `external\libs\windows\bin\` 폴더로

## 4. 폴더 구조 확인

설치가 완료되면 다음 파일들이 반드시 있어야 합니다:
- `external\libs\windows\include\client.h`
- `external\libs\windows\lib\mpv.dll.a`
- `external\libs\windows\bin\libmpv-2.dll`

## 5. 빌드 실행

파일 설치 후 `build.bat`를 실행합니다. CMake 및 C++ 컴파일러가 설치되어 있어야 합니다. 