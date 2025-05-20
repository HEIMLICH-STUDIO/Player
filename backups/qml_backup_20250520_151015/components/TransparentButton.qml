import QtQuick
import QtQuick.Controls

// Transparent button with icon
Button {
    id: control
    
    property color borderColorNormal: "#555555"
    property color textColorNormal: "#FFFFFF"
    property color textColorHover: "#0078D7" // Default accent color
    property int buttonRadius: 2
    property bool useIcon: false
    property string iconSource: ""
    property int iconSize: 16
    
    contentItem: Item {
        implicitWidth: useIcon ? iconDisplay.width + 10 : textItem.implicitWidth + 20
        implicitHeight: useIcon ? iconDisplay.height + 10 : textItem.implicitHeight + 10

        Text {
            id: textItem
            visible: !control.useIcon
            text: control.text
            font.pixelSize: 13
            font.weight: Font.Medium
            color: control.hovered ? control.textColorHover : 
                   control.enabled ? control.textColorNormal : "#888888"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.centerIn: parent
            font.family: "Segoe UI"
        }
        
        IconDisplay {
            id: iconDisplay
            visible: control.useIcon && control.iconSource !== ""
            iconName: control.iconSource
            size: control.iconSize
            iconColor: control.textColorNormal
            hoverColor: control.textColorHover
            isHovered: control.hovered
            isPressed: control.down
            anchors.centerIn: parent
        }
    }
    
    background: Rectangle {
        radius: control.buttonRadius
        color: "transparent"
        border.width: control.hovered ? 1 : 0
        border.color: control.hovered ? control.borderColorNormal : "transparent"
    }
} 