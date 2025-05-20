import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../ui"
import "../utils"

// Bottom control bar for media playback
Rectangle {
    id: controlBar
    height: 90
    color: ThemeManager.panelColor
    
    // Properties
    property var mpvObject: null  // Reference to MpvObject
    property int currentFrame: 0
    property int totalFrames: 1000
    property real fps: 24.0
    property bool mpvSupported: true
    
    // Signals
    signal openFileRequested()
    signal toggleSettingsPanelRequested()
    signal takeScreenshotRequested()
    signal toggleFullscreenRequested()
    signal toggleScopesRequested()
    signal frameBackwardRequested(int frames)
    signal frameForwardRequested(int frames)
    
    // Timeline area for external component
    Item {
        id: timelineArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 40  // Timeline height
    }
    
    // Add a subtle top border
    Rectangle {
        height: 1
        anchors.top: timelineArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: ThemeManager.borderColor
    }
    
    // Main content layout
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: timelineArea.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 6
        
        // Player controls - bottom
        Rectangle {
            id: controlsRow
            height: 32
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                spacing: 5
                
                // Left info area
                RowLayout {
                    Text {
                        text: fps.toFixed(2) + " fps"
                        color: ThemeManager.secondaryTextColor
                        font.pixelSize: ThemeManager.smallFontSize
                        font.family: ThemeManager.monoFont
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Center control area
                RowLayout {
                    spacing: 8
                    
                    IconButton {
                        iconSource: "rewind"
                        iconSize: 16
                        tipText: "Go to Start"
                        onClicked: {
                            if (mpvObject) {
                                mpvObject.setProperty("time-pos", 0);
                            }
                        }
                    }
                    
                    IconButton {
                        iconSource: "frame_backward"
                        iconSize: 16
                        tipText: "Back 10 Frames"
                        onClicked: {
                            frameBackwardRequested(10);
                        }
                    }
                    
                    IconButton {
                        iconSource: "backward"
                        iconSize: 16
                        tipText: "Previous Frame"
                        onClicked: {
                            frameBackwardRequested(1);
                        }
                    }
                    
                    IconButton {
                        iconSource: mpvObject && mpvObject.pause ? "play" : "pause"
                        iconSize: 20
                        width: 40
                        height: 40
                        tipText: mpvObject && mpvObject.pause ? "Play" : "Pause"
                        textColorNormal: ThemeManager.iconColor
                        textColorHover: ThemeManager.accentColor
                        onClicked: {
                            if (mpvObject) {
                                mpvObject.playPause();
                            } else if (mpvSupported) {
                                openFileRequested();
                            }
                        }
                    }
                    
                    IconButton {
                        iconSource: "forward"
                        iconSize: 16
                        tipText: "Next Frame"
                        onClicked: {
                            frameForwardRequested(1);
                        }
                    }
                    
                    IconButton {
                        iconSource: "frame_forward"
                        iconSize: 16
                        tipText: "Forward 10 Frames"
                        onClicked: {
                            frameForwardRequested(10);
                        }
                    }
                    
                    IconButton {
                        iconSource: "fast_forward"
                        iconSize: 16
                        tipText: "Go to End"
                        onClicked: {
                            if (mpvObject && mpvObject.duration) {
                                // Go to last frame
                                mpvObject.setProperty("time-pos", mpvObject.duration - (1/fps));
                            }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Right control area
                RowLayout {
                    spacing: 6
                    
                    IconButton {
                        iconSource: "folder"
                        iconSize: 16
                        tipText: "Open File"
                        width: 32
                        height: 32
                        onClicked: openFileRequested()
                    }
                    
                    IconButton {
                        iconSource: "settings"
                        iconSize: 16
                        tipText: "Toggle Settings"
                        width: 32
                        height: 32
                        onClicked: toggleSettingsPanelRequested()
                    }
                    
                    IconButton {
                        iconSource: "screenshot"
                        iconSize: 16
                        tipText: "Take Screenshot"
                        width: 32
                        height: 32
                        onClicked: takeScreenshotRequested()
                    }

                    IconButton {
                        iconSource: "scopes"
                        iconSize: 16
                        tipText: "Toggle Scopes"
                        width: 32
                        height: 32
                        onClicked: toggleScopesRequested()
                    }

                    IconButton {
                        id: fullscreenButton
                        iconSource: "fullscreen"
                        iconSize: 16
                        tipText: "Toggle Fullscreen"
                        width: 32
                        height: 32
                        onClicked: toggleFullscreenRequested()
                    }
                }
            }
        }
        
        // Spacer line
        Rectangle {
            height: 1
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: controlsRow.top
            anchors.bottomMargin: 4
            color: ThemeManager.borderColor
            opacity: 0.5
        }
    }
} 