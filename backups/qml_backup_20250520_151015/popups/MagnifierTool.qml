import QtQuick
import QtQuick.Controls

// Magnifier tool - styled professionally like in DJV
Rectangle {
    id: magnifier
    width: 200
    height: 200
    color: "#1E1E1E" // Control background color
    border.color: "#333333" // Border color
    border.width: 1
    visible: false
    
    // Title bar
    Rectangle {
        id: magnifierTitleBar
        height: 24
        color: "#181818" // Dark control color
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        
        Text {
            text: "Magnifier"
            color: "#FFFFFF" // Text color
            font.pixelSize: 12
            font.family: "Segoe UI"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
        }
        
        // Close button
        Rectangle {
            width: 20
            height: 20
            radius: 2
            color: "transparent"
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            
            Text {
                text: "✕"
                anchors.centerIn: parent
                color: "#FFFFFF" // Text color
                font.pixelSize: 12
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: magnifier.visible = false
                hoverEnabled: true
                onEntered: parent.color = Qt.rgba(1, 1, 1, 0.1)
                onExited: parent.color = "transparent"
            }
        }
    }
    
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        anchors.topMargin: magnifierTitleBar.height + 1
        color: "black" // Magnifier area
    }
    
    // Drag functionality
    MouseArea {
        anchors.fill: parent
        drag.target: magnifier
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: parent.width - magnifier.width
        drag.maximumY: parent.height - magnifier.height
        drag.filterChildren: true  // Lets child mouse areas receive events
    }
    
    // Show/hide the magnifier
    function show() {
        visible = true;
    }
    
    function hide() {
        visible = false;
    }
    
    function toggle() {
        visible = !visible;
    }
} 