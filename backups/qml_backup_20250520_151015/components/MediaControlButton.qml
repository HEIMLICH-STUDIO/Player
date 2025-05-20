import QtQuick
import QtQuick.Controls

// Media control buttons with professional styling
Button {
    id: control
    
    property color buttonColor: "transparent"
    property color textColorNormal: "#FFFFFF"
    property color textColorHover: "#0078D7" // Default accent color
    property int buttonRadius: 2
    property bool useIcon: true
    property string iconSource: ""
    property int iconSize: 18
    
    contentItem: Item {
        // Import the IconDisplay component
        IconDisplay {
            anchors.centerIn: parent
            iconName: control.iconSource
            size: control.iconSize
            iconColor: control.textColorNormal
            hoverColor: control.textColorHover
            isHovered: control.hovered
            isPressed: control.pressed
        }
    }
    
    background: Rectangle {
        implicitWidth: 32
        implicitHeight: 32
        radius: control.buttonRadius
        color: "transparent"
    }
} 