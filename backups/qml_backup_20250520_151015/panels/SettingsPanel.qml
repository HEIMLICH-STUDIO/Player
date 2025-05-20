import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Import local components
import "../components"
import "../utils"

Rectangle {
    id: settingsPanel
    
    // Required properties
    property color accentColor
    property color secondaryColor
    property color textColor
    property color panelColor
    property color controlBgColor
    property color darkControlColor
    property color borderColor
    property string mainFont
    property string monoFont
    property alias mpvPlayer: internalRoot.mpvPlayer
    property real fps
    
    // Internal root for references
    QtObject {
        id: internalRoot
        property var mpvPlayer: null
    }
    
    // Settings panel content
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Panel title
        Text {
            text: qsTr("Settings")
            color: textColor
            font.bold: true
            font.pixelSize: 16
            Layout.fillWidth: true
            font.family: mainFont
        }
        
        // Tab control - professional styling
        TabBar {
            id: settingsTabs
            Layout.fillWidth: true
            
            background: Rectangle {
                color: darkControlColor
                radius: 2
                border.color: borderColor
                border.width: 1
            }
            
            TabButton {
                text: qsTr("General")
                font.family: mainFont
                font.pixelSize: 12
                
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "transparent"
                    border.color: parent.checked ? accentColor : "transparent"
                    border.width: parent.checked ? 1 : 0
                    radius: 0
                }
            }
            TabButton {
                text: qsTr("Video")
                font.family: mainFont
                font.pixelSize: 12
                
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "transparent"
                    border.color: parent.checked ? accentColor : "transparent"
                    border.width: parent.checked ? 1 : 0
                    radius: 0
                }
            }
            TabButton {
                text: qsTr("Audio")
                font.family: mainFont
                font.pixelSize: 12
                
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "transparent"
                    border.color: parent.checked ? accentColor : "transparent"
                    border.width: parent.checked ? 1 : 0
                    radius: 0
                }
            }
            TabButton {
                text: qsTr("Tools")
                font.family: mainFont
                font.pixelSize: 12
                
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "transparent"
                    border.color: parent.checked ? accentColor : "transparent"
                    border.width: parent.checked ? 1 : 0
                    radius: 0
                }
            }
        }
        
        // Tab contents
        StackLayout {
            currentIndex: settingsTabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // General settings tab
            GeneralSettingsTab {
                accentColor: settingsPanel.accentColor
                secondaryColor: settingsPanel.secondaryColor
                textColor: settingsPanel.textColor
                panelColor: settingsPanel.panelColor
                controlBgColor: settingsPanel.controlBgColor
                darkControlColor: settingsPanel.darkControlColor
                borderColor: settingsPanel.borderColor
                mainFont: settingsPanel.mainFont
                monoFont: settingsPanel.monoFont
                mpvPlayer: settingsPanel.mpvPlayer
                fps: settingsPanel.fps
            }
            
            // Video settings tab
            VideoSettingsTab {
                accentColor: settingsPanel.accentColor
                secondaryColor: settingsPanel.secondaryColor
                textColor: settingsPanel.textColor
                panelColor: settingsPanel.panelColor
                controlBgColor: settingsPanel.controlBgColor
                borderColor: settingsPanel.borderColor
                mpvPlayer: settingsPanel.mpvPlayer
            }
            
            // Audio settings tab placeholder
            Item {
                // Audio settings tab will go here
            }
            
            // Tools tab placeholder
            Item {
                // Tools tab will go here
            }
        }
    }
} 