import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// CustomStatusBar for displaying media info and status
Rectangle {
    id: customStatusBar
    height: 24
    color: darkControlColor
    visible: true
    
    // Properties
    property string currentMediaFile: ""
    property int currentFrame: 0
    property int totalFrames: 1
    property color borderColor: "#333333"
    property color darkControlColor: "#181818"
    property string mainFont: "Segoe UI"
    property string monoFont: "Consolas"
    
    // Border on top
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: borderColor
    }
    
    // Status layout
    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 10
        
        // Filename
        Text {
            text: currentMediaFile ? currentMediaFile.split('/').pop() : "No file loaded"
            color: "white"
            font.pixelSize: 12
            font.family: mainFont
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }
        
        // Frame counter
        Text {
            text: "Frame: " + currentFrame + " / " + totalFrames
            color: "white"
            font.pixelSize: 12
            font.family: monoFont
        }
    }
} 