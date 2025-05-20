import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../utils"

// Status bar showing current media information
Rectangle {
    id: statusBar
    height: 24
    color: ThemeManager.panelColor
    
    // Border styling
    Rectangle {
        height: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: ThemeManager.borderColor
    }
    
    // Properties
    property string currentMediaFile: ""
    property int currentFrame: 0
    property int totalFrames: 0
    
    // Layout for status items
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10
        
        // Filename
        Text {
            id: fileNameStatus
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.family: ThemeManager.defaultFont
            font.pixelSize: ThemeManager.smallFontSize
            color: ThemeManager.secondaryTextColor
            text: currentMediaFile ? 
                "File: " + (currentMediaFile.split('/').pop() || currentMediaFile.split('\\').pop()) : 
                "No file loaded"
            elide: Text.ElideMiddle
        }
        
        // Frame counter
        Text {
            id: frameCounter
            Layout.alignment: Qt.AlignVCenter
            font.family: ThemeManager.monoFont
            font.pixelSize: ThemeManager.smallFontSize
            color: ThemeManager.secondaryTextColor
            text: "Frame: " + currentFrame + " / " + totalFrames
        }
    }
} 