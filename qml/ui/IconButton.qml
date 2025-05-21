import QtQuick
import QtQuick.Controls

import "../utils"

// Icon button for QT 6+
Rectangle {
    id: root
    
    // Size settings
    width: 36
    height: 36
    radius: width / 2 // Make it circular
    
    // Style properties
    property string iconSource: ""
    property int iconSize: 16
    
    // Compatibility properties (for existing references in other files)
    property color textColorNormal: ThemeManager.controlIconColor
    property color textColorHover: ThemeManager.isDarkTheme ? 
                                  Qt.lighter(ThemeManager.controlIconColor, 1.3) : 
                                  Qt.darker(ThemeManager.controlIconColor, 1.3)
    property color textColorPressed: ThemeManager.accentColor
    property color textColorChecked: ThemeManager.accentColor
    
    property color bgColorNormal: "transparent"
    property color bgColorHover: ThemeManager.isDarkTheme ? 
                               Qt.rgba(1, 1, 1, 0.1) : 
                               Qt.rgba(0, 0, 0, 0.05)
    property color bgColorPressed: ThemeManager.isDarkTheme ? 
                                 Qt.rgba(1, 1, 1, 0.15) : 
                                 Qt.rgba(0, 0, 0, 0.1)
    property color bgColorChecked: ThemeManager.isDarkTheme ? 
                                 Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.2) : 
                                 Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.1)
    
    // State properties
    property bool enabled: true
    property bool hovered: area.containsMouse
    property bool pressed: area.pressed
    
    // Function properties
    property bool checkable: false
    property bool checked: false
    signal clicked()
    signal pressAndHold()
    
    // Tooltip text
    property string tipText: ""
    property bool showTip: tipText !== "" && area.containsMouse
    
    // Background color changes based on state with smooth transitions
    color: {
        if (!enabled) return "transparent";
        if (pressed) return bgColorPressed;
        if (checked) return bgColorChecked;
        if (hovered) return bgColorHover;
        return bgColorNormal;
    }
    
    // Smooth transition for background color
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    // Current icon color based on state
    property color currentIconColor: {
        if (!enabled) {
            return Qt.rgba(textColorNormal.r, textColorNormal.g, textColorNormal.b, 0.5);
        } else if (pressed) {
            return textColorPressed;
        } else if (checked) {
            return textColorChecked;
        } else if (hovered) {
            return textColorHover;
        } else {
            return textColorNormal;
        }
    }
    
    // Smooth transition for icon color
    Behavior on currentIconColor {
        ColorAnimation { duration: 150 }
    }
    
    // Simple SVG icon 
    Image {
        id: iconImage
        anchors.centerIn: parent
        source: {
            if (!iconSource) return "";
            
            if (iconSource.startsWith("qrc:") || 
                iconSource.startsWith("/") || 
                iconSource.startsWith("file:") || 
                iconSource.startsWith("http")) {
                return iconSource;
            }
            
            return "../../assets/icons/" + iconSource + ".svg";
        }
        width: iconSize
        height: iconSize
        sourceSize.width: iconSize * 2
        sourceSize.height: iconSize * 2
        fillMode: Image.PreserveAspectFit
        visible: false // Hide the original image, we'll display the colored version
    }
    
    // Color overlay using Canvas
    Canvas {
        id: colorOverlay
        anchors.centerIn: parent
        width: iconImage.width
        height: iconImage.height
        visible: iconImage.status === Image.Ready
        
        // Update when icon color changes
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            if (iconImage.status === Image.Ready) {
                // Draw the icon
                ctx.globalCompositeOperation = "source-over";
                ctx.drawImage(iconImage, 0, 0, width, height);
                
                // Apply color overlay
                ctx.globalCompositeOperation = "source-in";
                ctx.fillStyle = currentIconColor;
                ctx.fillRect(0, 0, width, height);
            }
        }
        
        // 초기화 시 Canvas를 강제로 그리도록 함
        Component.onCompleted: {
            // 시작 시 즉시 첫 렌더링 수행
            Qt.callLater(function() {
                colorOverlay.requestPaint();
                console.log("Canvas initialized for icon:", root.iconSource);
            });
        }
        
        // Update canvas when color or image changes
        Connections {
            target: root
            function onCurrentIconColorChanged() { colorOverlay.requestPaint(); }
        }
        
        Connections {
            target: iconImage
            function onStatusChanged() {
                if (iconImage.status === Image.Ready) {
                    console.log("Icon loaded:", root.iconSource);
                    colorOverlay.requestPaint();
                }
            }
        }
        
        // Smooth scaling when hovered
        scale: root.hovered ? 1.1 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }
    
    // Mouse area for interaction
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            if (!root.enabled) return;
            if (root.checkable) {
                root.checked = !root.checked;
            }
            root.clicked();
        }
        
        onPressAndHold: {
            if (root.enabled) root.pressAndHold();
        }
    }
    
    // Tooltip
    Rectangle {
        id: toolTip
        visible: showTip
        opacity: showTip ? 1.0 : 0
        color: ThemeManager.isDarkTheme ? Qt.rgba(0.15, 0.15, 0.15, 0.95) : Qt.rgba(0.95, 0.95, 0.95, 0.95)
        radius: 3
        width: toolTipText.width + 12
        height: toolTipText.height + 8
        
        // Position tooltip below button
        x: (parent.width - width) / 2
        y: parent.height + 5
        
        // Add subtle border
        border.width: 1
        border.color: ThemeManager.isDarkTheme ? Qt.rgba(0.3, 0.3, 0.3, 0.5) : Qt.rgba(0.7, 0.7, 0.7, 0.5)
        
        // Tooltip text
        Text {
            id: toolTipText
            text: root.tipText
            anchors.centerIn: parent
            color: ThemeManager.textColor
            font.pixelSize: 11
            font.family: ThemeManager.defaultFont
        }
        
        // Animation
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }
    
    Component.onCompleted: {
        console.log("IconButton created: " + iconSource);
    }
} 