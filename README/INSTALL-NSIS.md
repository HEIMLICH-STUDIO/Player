# NSIS (Nullsoft Scriptable Install System) 설치 가이드

## 📋 **NSIS란?**

NSIS는 Windows용 프로페셔널 인스톨러 생성 도구입니다.
- **무료 오픈소스** 
- **작은 크기** (2-3MB)
- **강력한 기능** (스크립트 기반)
- **널리 사용됨** (많은 유명 소프트웨어가 사용)

## 🔧 **설치 방법**

### **1단계: NSIS 다운로드**
- **공식 사이트**: https://nsis.sourceforge.io/
- **직접 다운로드**: https://nsis.sourceforge.io/Download
- **최신 버전 권장** (3.09 이상)

### **2단계: NSIS 설치**
1. 다운로드한 `nsis-X.XX-setup.exe` 실행
2. **"I Agree"** 클릭 (라이센스 동의)
3. **설치 경로 확인**: 
   - 기본: `C:\Program Files (x86)\NSIS`
   - 또는: `C:\Program Files\NSIS`
4. **"Install"** 클릭
5. 설치 완료 후 **"Close"** 클릭

### **3단계: 설치 확인**
설치 완료 후 다음 파일이 있는지 확인:
```
C:\Program Files (x86)\NSIS\makensis.exe
```

## ✅ **빠른 테스트**

명령 프롬프트에서 테스트:
```batch
"C:\Program Files (x86)\NSIS\makensis.exe" /VERSION
```

버전 정보가 출력되면 성공! 🎉

## 🚀 **Player by HEIMLICH® 인스톨러 생성**

### **사전 준비**
1. **앱 빌드 완료**: `build.bat` 실행 완료
2. **NSIS 설치 완료**: 위 단계 완료
3. **파일 확인**:
   ```
   ✅ build\Player-by-HEIMLICH.exe (존재)
   ✅ installer.nsi (존재)
   ✅ LICENSE.txt (존재)
   ```

### **인스톨러 생성**
```batch
create-installer.bat
```

### **생성되는 파일**
```
Player by HEIMLICH®-Setup-v1.0.0.exe
```

## 🎯 **인스톨러 기능**

### **✨ 사용자 친화적 UI**
- 🎨 Modern UI 2.0 사용
- 🌍 다국어 지원 (English/Korean)
- 📋 라이센스 페이지
- 🎛️ 컴포넌트 선택
- 📂 설치 경로 선택

### **🔧 설치 옵션**
- ✅ **메인 프로그램** (필수)
- ✅ **시작 메뉴 바로가기**
- ✅ **파일 연결** (.mp4, .avi, .mkv 등)
- ✅ **바탕화면 바로가기** (선택)

### **📦 포함 내용**
- Player by HEIMLICH® 실행파일
- 모든 Qt 의존성 라이브러리
- MPV 비디오 라이브러리
- 에셋 파일들 (아이콘, 이미지 등)
- 다국어 번역 파일

### **🛠️ 시스템 통합**
- Windows 프로그램 목록에 등록
- 제어판에서 제거 가능
- 비디오 파일 연결 (우클릭 메뉴)
- 레지스트리 정리

## 🔧 **문제 해결**

### **Q: "NSIS not found" 에러**
**해결책**:
1. NSIS가 제대로 설치되었는지 확인
2. `create-installer.bat`에서 경로 수정:
   ```batch
   set "NSIS_PATH=C:\Program Files\NSIS"
   ```

### **Q: 빌드 에러 발생**
**해결책**:
1. `build.bat` 먼저 실행
2. `build\Player-by-HEIMLICH.exe` 파일 존재 확인
3. `LICENSE.txt` 파일 존재 확인

### **Q: 인스톨러가 실행되지 않음**
**해결책**:
1. 바이러스 백신 예외 추가
2. 관리자 권한으로 실행
3. Windows Defender SmartScreen 허용

## 📏 **파일 크기 비교**

| 도구 | 인스톨러 크기 | 압축률 | 설치시간 |
|------|-------------|--------|---------|
| **NSIS** | ~50-80MB | 우수 | 빠름 |
| Qt IFW | ~70-100MB | 보통 | 보통 |
| WiX | ~60-90MB | 좋음 | 느림 |

## 💡 **장점**

### **🎯 NSIS 장점**
- ✅ **무료** - 완전 무료 오픈소스
- ✅ **가벼움** - 작은 설치 파일
- ✅ **빠름** - 빠른 설치 속도
- ✅ **안정적** - 검증된 솔루션
- ✅ **유연함** - 완전 커스터마이징 가능
- ✅ **호환성** - 모든 Windows 버전 지원

### **🚀 Qt IFW 대비 장점**
- ❌ Qt 계정 불필요
- ❌ 복잡한 설정 불필요  
- ✅ 더 작은 파일 크기
- ✅ 더 빠른 빌드 시간
- ✅ 더 많은 사용 예제

## 🎨 **커스터마이징**

### **버전 변경**
`installer.nsi` 파일에서:
```nsis
!define APP_VERSION "1.1.0"
```

### **아이콘 변경**
```nsis
!define MUI_ICON "assets\images\installer.ico"
!define MUI_UNICON "assets\images\uninstaller.ico"
```

### **이미지 추가**
```nsis
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "assets\images\header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "assets\images\welcome.bmp"
```

## 📞 **지원**

- **NSIS 공식 문서**: https://nsis.sourceforge.io/Docs/
- **커뮤니티 포럼**: https://forums.winamp.com/forum/47-nsis-discussion/
- **예제 모음**: https://nsis.sourceforge.io/Examples

## 🎉 **완료!**

이제 프로페셔널한 Windows 인스톨러가 준비되었습니다! 🚀 