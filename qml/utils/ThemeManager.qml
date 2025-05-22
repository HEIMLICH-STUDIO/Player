pragma Singleton
import QtQuick

// Global app theme manager
QtObject {
    id: themeManager
    
    // Theme mode - dark/light mode support
    property string currentTheme: "dark" // "dark" or "light"
    readonly property bool isDarkTheme: currentTheme === "dark"
    
    // Professional color definitions - higher contrast
    readonly property color accentColor: isDarkTheme ? "#00B8FF" : "#0078D4" // Professional blue
    readonly property color accentColorHover: isDarkTheme ? "#33C9FF" : "#1683DA"
    readonly property color accentColorActive: isDarkTheme ? "#009DDB" : "#0069BC"
    
    // Background colors - neutral for professional look
    readonly property color backgroundColor: isDarkTheme ? "#000000" : "#F0F0F0" // Darker like Nuke
    readonly property color panelColor: isDarkTheme ? "#000000" : "#FFFFFF" // DaVinci style panels
    readonly property color controlBgColor: isDarkTheme ? "#000000" : "#E9E9E9"
    readonly property color darkControlColor: isDarkTheme ? "#000000" : "#D8D8D8"
    readonly property color dialogColor: isDarkTheme ? "#000000" : "#FFFFFF"
    
    // Borders - subtle in professional apps
    readonly property color borderColor: isDarkTheme ? "#151515" : "#DADADA"
    
    // Text colors - clean and professional
    readonly property color textColor: isDarkTheme ? "#EFEFEF" : "#202020"
    readonly property color secondaryTextColor: isDarkTheme ? "#B0B0B0" : "#505050"
    readonly property color disabledTextColor: isDarkTheme ? "#707070" : "#9E9E9E"
    readonly property color linkTextColor: isDarkTheme ? "#00B8FF" : "#0078D4"
    
    // Icon colors - clean and flat style
    readonly property color iconColor: isDarkTheme ? "#DADADA" : "#404040"
    readonly property color iconHoverColor: accentColor
    readonly property color iconActiveColor: accentColorActive
    readonly property color controlIconColor: isDarkTheme ? "#CCCCCC" : "#505050"
    readonly property color controlIconHoverColor: isDarkTheme ? "#FFFFFF" : "#303030"
    
    // Button colors - professional flat style
    readonly property color buttonColor: isDarkTheme ? "#2A78C5" : "#0078D4"
    readonly property color buttonHoverColor: isDarkTheme ? "#3384D1" : "#1683DA" 
    readonly property color buttonPressedColor: isDarkTheme ? "#1E6CB9" : "#0069BC"
    readonly property color buttonTextColor: "#FFFFFF"
    
    // Control buttons - player controls design
    readonly property color controlButtonColor: isDarkTheme ? "#404040" : "#777777"
    readonly property color controlButtonHoverColor: isDarkTheme ? "#505050" : "#888888"
    readonly property color controlButtonPressedColor: isDarkTheme ? "#303030" : "#666666"
    readonly property color controlButtonTextColor: isDarkTheme ? "#FFFFFF" : "#FFFFFF"
    readonly property int controlButtonRadius: 14  // 캡슐형 버튼 반지름
    readonly property int controlButtonHeight: 28  // 컨트롤 버튼 높이
    readonly property int controlBarHeight: 80  // 컨트롤바 높이 (타임라인 제외)
    readonly property int hoverAnimationDuration: 150  // 호버 애니메이션 지속 시간 (ms)
    
    // Scrollbar style - minimal like pro apps
    readonly property color scrollBarColor: isDarkTheme ? "#4D4D4D" : "#C0C0C0"
    readonly property color scrollBarHoverColor: isDarkTheme ? "#666666" : "#A0A0A0"
    readonly property color scrollBarActiveColor: isDarkTheme ? "#808080" : "#808080"
    readonly property color scrollBarBgColor: "transparent"
    readonly property int scrollBarWidth: 6 // Thinner scrollbars
    readonly property int scrollBarRadius: 3
    
    // Tab style - cleaner look
    readonly property color tabBarColor: isDarkTheme ? "#232323" : "#F5F5F5"
    readonly property color tabButtonColor: isDarkTheme ? "#282828" : "#F0F0F0"
    readonly property color tabButtonActiveColor: isDarkTheme ? "#00B8FF" : "#0078D4"
    readonly property color tabButtonTextColor: isDarkTheme ? "#B0B0B0" : "#505050"
    readonly property color tabButtonActiveTextColor: isDarkTheme ? "#FFFFFF" : "#FFFFFF"
    readonly property color tabContentColor: isDarkTheme ? "#232323" : "#FFFFFF"
    
    // Timeline UI elements - professional video editor style
    readonly property color timelineBackgroundColor: isDarkTheme ? "#000000" : "#E9E9E9"
    readonly property color timelineFrameColor: isDarkTheme ? "#1e1e1e" : "#BBBBBB"
    readonly property color timelineMajorFrameColor: isDarkTheme ? "#252525" : "#888888" 
    readonly property color timelinePlayheadColor: "#FF453A" // Apple-inspired playhead
    readonly property color timelineActiveTrackColor: Qt.rgba(1.0, 1.0, 1.0, 0.15) // 투명한 흰색
    
    // Debug logging
    onCurrentThemeChanged: {
        console.log("Theme changed to:", currentTheme);
    }
    
    // Text sizes
    readonly property int smallFontSize: 11
    readonly property int normalFontSize: 12
    readonly property int largeFontSize: 14
    readonly property int titleFontSize: 16
    
    // Fonts
    readonly property string defaultFont: "Segoe UI"
    readonly property string monoFont: "Consolas"
    
    // Theme switching
    function toggleTheme() {
        currentTheme = isDarkTheme ? "light" : "dark"
        // Save preference (to be implemented)
        // saveThemePreference(currentTheme)
    }
    
    // Set specific theme
    function setTheme(theme) {
        if (theme === "dark" || theme === "light") {
            currentTheme = theme
            // saveThemePreference(currentTheme)
        }
    }
    
    // 아이콘 및 UI 색상 강제 새로고침
    function refreshColors() {
        // 시스템에 현재 테마 변경됨을 알림 (바인딩 갱신 효과)
        var temp = currentTheme
        currentTheme = ""
        currentTheme = temp
        
        console.log("Theme colors refreshed")
    }
    
    Component.onCompleted: {
        console.log("ThemeManager initialized with theme:", currentTheme)
        
        // 앱 시작 시 300ms 후에 색상 강제 새로고침 (모든 컴포넌트 로드 후)
        Qt.callLater(function() {
            refreshColors()
        })
    }
} 