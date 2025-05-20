pragma Singleton
import QtQuick

// 앱 전체 테마 관리
QtObject {
    id: themeManager
    
    // 테마 모드 - 다시 다크/라이트 모드 지원
    property string currentTheme: "dark" // "dark" 또는 "light"
    readonly property bool isDarkTheme: currentTheme === "dark"
    
    // 색상 정의 - 더 명확한 대비
    readonly property color accentColor: isDarkTheme ? "#4499FF" : "#0066CC"
    readonly property color accentColorHover: isDarkTheme ? "#66AAFF" : "#0077EE"
    readonly property color accentColorActive: isDarkTheme ? "#3377DD" : "#0055BB"
    
    // 배경색 - 테마에 따라 다른 색상 적용
    readonly property color backgroundColor: isDarkTheme ? "#121212" : "#F5F5F5"
    readonly property color panelColor: isDarkTheme ? "#1E1E1E" : "#FFFFFF"
    readonly property color controlBgColor: isDarkTheme ? "#252525" : "#E5E5E5"
    readonly property color darkControlColor: isDarkTheme ? "#2A2A2A" : "#D0D0D0"
    readonly property color dialogColor: isDarkTheme ? "#282828" : "#FFFFFF"
    
    // 경계선 - 테마에 따라 다른 색상
    readonly property color borderColor: isDarkTheme ? "#555555" : "#CCCCCC"
    
    // 텍스트 색상 - 테마별 설정
    readonly property color textColor: isDarkTheme ? "#FFFFFF" : "#000000"
    readonly property color secondaryTextColor: isDarkTheme ? "#CCCCCC" : "#555555"
    readonly property color disabledTextColor: isDarkTheme ? "#888888" : "#999999"
    readonly property color linkTextColor: isDarkTheme ? "#66AAFF" : "#0077CC"
    
    // 아이콘 색상 - 테마별 설정
    readonly property color iconColor: isDarkTheme ? "#FFFFFF" : "#333333"
    readonly property color iconHoverColor: accentColor
    readonly property color iconActiveColor: accentColorActive
    readonly property color controlIconColor: isDarkTheme ? "#DDDDDD" : "#444444"
    readonly property color controlIconHoverColor: isDarkTheme ? "#FFFFFF" : "#222222"
    
    // 버튼 색상
    readonly property color buttonColor: isDarkTheme ? "#3c80c0" : "#0066CC"
    readonly property color buttonHoverColor: isDarkTheme ? "#4488CC" : "#0077DD" 
    readonly property color buttonPressedColor: isDarkTheme ? "#2a6496" : "#004499"
    readonly property color buttonTextColor: "#FFFFFF"
    
    // 스크롤바 스타일
    readonly property color scrollBarColor: isDarkTheme ? "#555555" : "#CCCCCC"
    readonly property color scrollBarHoverColor: isDarkTheme ? "#777777" : "#AAAAAA"
    readonly property color scrollBarActiveColor: isDarkTheme ? "#999999" : "#888888"
    readonly property color scrollBarBgColor: "transparent"
    readonly property int scrollBarWidth: 8
    readonly property int scrollBarRadius: 4
    
    // 탭 스타일
    readonly property color tabBarColor: isDarkTheme ? "#252525" : "#F0F0F0"
    readonly property color tabButtonColor: isDarkTheme ? "#1E1E1E" : "#F0F0F0"
    readonly property color tabButtonActiveColor: isDarkTheme ? "#3c80c0" : "#0066CC"
    readonly property color tabButtonTextColor: isDarkTheme ? "#CCCCCC" : "#333333"
    readonly property color tabButtonActiveTextColor: isDarkTheme ? "#FFFFFF" : "#FFFFFF"
    readonly property color tabContentColor: isDarkTheme ? "#1E1E1E" : "#FFFFFF"
    
    // 특수 UI 요소 - 테마에 따른 색상
    readonly property color timelineBackgroundColor: isDarkTheme ? "#1E1E1E" : "#E5E5E5"
    readonly property color timelineFrameColor: isDarkTheme ? "#555555" : "#AAAAAA"
    readonly property color timelineMajorFrameColor: isDarkTheme ? "#888888" : "#777777" 
    readonly property color timelinePlayheadColor: "#FF5555"
    
    // 테마 변경 시 로그 출력 (디버깅용)
    onCurrentThemeChanged: {
        console.log("Theme changed to:", currentTheme);
    }
    
    // 텍스트 크기
    readonly property int smallFontSize: 11
    readonly property int normalFontSize: 13
    readonly property int largeFontSize: 15
    readonly property int titleFontSize: 17
    
    // 글꼴
    readonly property string defaultFont: "Segoe UI"
    readonly property string monoFont: "Consolas"
    
    // 테마 전환
    function toggleTheme() {
        currentTheme = isDarkTheme ? "light" : "dark"
        // 설정 저장 (추후 구현)
        // saveThemePreference(currentTheme)
    }
    
    // 특정 테마로 설정
    function setTheme(theme) {
        if (theme === "dark" || theme === "light") {
            currentTheme = theme
            // saveThemePreference(currentTheme)
        }
    }
    
    Component.onCompleted: {
        console.log("ThemeManager initialized with theme:", currentTheme)
    }
} 