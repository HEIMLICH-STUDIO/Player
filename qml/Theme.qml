pragma Singleton
import QtQuick

QtObject {
    id: theme
    
    // Theme mode
    property bool isDarkMode: true
    
    // Colors - Dark mode
    readonly property color darkBackground: "#121212"
    readonly property color darkHeader: "#1E1E1E"
    readonly property color darkAccent: "#8C3FFF"
    readonly property color darkText: "#FFFFFF"
    readonly property color darkSecondaryText: "#B3B3B3"
    readonly property color darkButton: "#2A2A2A"
    readonly property color darkButtonHover: "#404040"
    readonly property color darkControl: "#333333"
    readonly property color darkSlider: "#8C3FFF" 
    readonly property color darkProgress: "#8C3FFF"
    
    // Colors - Light mode
    readonly property color lightBackground: "#F5F5F5"
    readonly property color lightHeader: "#FFFFFF"
    readonly property color lightAccent: "#6200EE"
    readonly property color lightText: "#000000"
    readonly property color lightSecondaryText: "#5F5F5F"
    readonly property color lightButton: "#E0E0E0"
    readonly property color lightButtonHover: "#BDBDBD"
    readonly property color lightControl: "#E0E0E0"
    readonly property color lightSlider: "#6200EE"
    readonly property color lightProgress: "#6200EE"
    
    // Dynamic properties based on theme mode
    property color backgroundColor: isDarkMode ? darkBackground : lightBackground
    property color headerColor: isDarkMode ? darkHeader : lightHeader
    property color accentColor: isDarkMode ? darkAccent : lightAccent
    property color primaryTextColor: isDarkMode ? darkText : lightText
    property color secondaryTextColor: isDarkMode ? darkSecondaryText : lightSecondaryText
    property color buttonColor: isDarkMode ? darkButton : lightButton
    property color buttonHoverColor: isDarkMode ? darkButtonHover : lightButtonHover
    property color controlColor: isDarkMode ? darkControl : lightControl
    property color sliderColor: isDarkMode ? darkSlider : lightSlider
    property color progressColor: isDarkMode ? darkProgress : lightProgress
    
    // Update dynamic colors when theme mode changes
    onIsDarkModeChanged: {
        backgroundColor = isDarkMode ? darkBackground : lightBackground
        headerColor = isDarkMode ? darkHeader : lightHeader
        accentColor = isDarkMode ? darkAccent : lightAccent
        primaryTextColor = isDarkMode ? darkText : lightText
        secondaryTextColor = isDarkMode ? darkSecondaryText : lightSecondaryText
        buttonColor = isDarkMode ? darkButton : lightButton
        buttonHoverColor = isDarkMode ? darkButtonHover : lightButtonHover
        controlColor = isDarkMode ? darkControl : lightControl
        sliderColor = isDarkMode ? darkSlider : lightSlider
        progressColor = isDarkMode ? darkProgress : lightProgress
    }

    // 확장 색상
    property color accentColorLight: Qt.lighter(accentColor, 1.3)
    property color accentColorDark: Qt.darker(accentColor, 1.3)
    
    // 프로그레스 바 색상
    property color progressBarColor: accentColor
    property color progressBarBackgroundColor: isDarkMode ? "#3a3a3a" : "#d5d5d5"
    
    // 슬라이더 색상
    property color sliderHandleColor: accentColor
    property color sliderGrooveColor: isDarkMode ? "#3a3a3a" : "#d5d5d5"
    property color sliderProgressColor: accentColor
} 