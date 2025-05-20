import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

// Bottom control bar for media playback
Rectangle {
    id: controlBar
    height: 90
    color: "#1E1E1E" // Control background color
    
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
    signal frameBackwardRequested(int frames)
    signal frameForwardRequested(int frames)
    
    // Timeline area - 타임라인 바가 들어갈 자리 (외부에서 채워짐)
    Item {
        id: timelineArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 40  // 타임라인 바 높이
    }
    
    // Add a subtle top border
    Rectangle {
        height: 1
        anchors.top: timelineArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: "#333333" // Border color
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
                        color: "#FFFFFF" // Text color
                        font.pixelSize: 10
                        font.family: "Consolas"
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Center control area
                RowLayout {
                    spacing: 8
                    
                    MediaControlButton {
                        iconSource: "rewind"
                        iconSize: 16
                        onClicked: {
                            if (mpvObject) {
                                mpvObject.setProperty("time-pos", 0);
                            }
                        }
                    }
                    
                    MediaControlButton {
                        iconSource: "frame_backward"
                        iconSize: 16
                        onClicked: {
                            frameBackwardRequested(10);
                        }
                    }
                    
                    MediaControlButton {
                        iconSource: "backward"
                        iconSize: 16
                        onClicked: {
                            frameBackwardRequested(1);
                        }
                    }
                    
                    MediaControlButton {
                        iconSource: mpvObject && mpvObject.pause ? "play" : "pause"
                        iconSize: 18
                        textColorNormal: "#FFFFFF"
                        textColorHover: "#0078D7" // Accent color
                        implicitWidth: 36
                        implicitHeight: 36
                        onClicked: {
                            if (mpvObject) {
                                mpvObject.playPause();
                            } else if (mpvSupported) {
                                openFileRequested();
                            }
                        }
                    }
                    
                    MediaControlButton {
                        iconSource: "forward"
                        iconSize: 16
                        onClicked: {
                            frameForwardRequested(1);
                        }
                    }
                    
                    MediaControlButton {
                        iconSource: "frame_forward"
                        iconSize: 16
                        onClicked: {
                            frameForwardRequested(10);
                        }
                    }
                    
                    MediaControlButton {
                        iconSource: "fast_forward"
                        iconSize: 16
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
                    
                    TransparentButton {
                        useIcon: true
                        iconSource: "folder"
                        iconSize: 16
                        textColorNormal: "#FFFFFF" // Text color
                        implicitWidth: 28
                        implicitHeight: 28
                        onClicked: openFileRequested()
                    }
                    
                    TransparentButton {
                        useIcon: true
                        iconSource: "settings"
                        iconSize: 16
                        textColorNormal: "#FFFFFF" // Text color
                        implicitWidth: 28
                        implicitHeight: 28
                        onClicked: toggleSettingsPanelRequested()
                    }
                    
                    TransparentButton {
                        useIcon: true
                        iconSource: "screenshot"
                        iconSize: 16
                        textColorNormal: "#FFFFFF" // Text color
                        implicitWidth: 28
                        implicitHeight: 28
                        onClicked: takeScreenshotRequested()
                    }
                    
                    TransparentButton {
                        id: fullscreenButton
                        useIcon: true
                        iconSource: "fullscreen" // Will be updated from main.qml
                        iconSize: 16
                        textColorNormal: "#FFFFFF" // Text color
                        implicitWidth: 28
                        implicitHeight: 28
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
            color: "#333333" // Border color
            opacity: 0.5
        }
    }
} 