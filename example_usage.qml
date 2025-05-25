import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "MPV Player with Keep-Open and Precise Seeking"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        // Video player area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "black"
            
            MpvObject {
                id: mpvPlayer
                anchors.fill: parent
                
                // New properties we added
                keepOpen: true  // Enable keep-open functionality
                
                onEndReached: {
                    console.log("Video ended - last frame should be visible due to keep-open")
                }
                
                onKeepOpenChanged: {
                    console.log("Keep-open mode changed to:", keepOpen)
                }
            }
        }

        // Control panel
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            Button {
                text: "Play/Pause"
                onClicked: mpvPlayer.playPause()
            }

            Button {
                text: "First Frame"
                onClicked: mpvPlayer.seekToFirstFrame()
                ToolTip.text: "Jump to first frame with precise positioning"
            }

            Button {
                text: "Last Frame"
                onClicked: mpvPlayer.seekToLastFrame()
                ToolTip.text: "Jump to last frame using 'seek 100 absolute-percent+exact'"
            }

            CheckBox {
                text: "Keep Open"
                checked: mpvPlayer.keepOpen
                onCheckedChanged: mpvPlayer.keepOpen = checked
                ToolTip.text: "Keep last frame visible when video ends"
            }

            CheckBox {
                text: "Loop"
                checked: mpvPlayer.loop
                onCheckedChanged: mpvPlayer.loop = checked
            }
        }

        // Status information
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Position: " + mpvPlayer.position.toFixed(3) + "s"
            }

            Text {
                text: "Duration: " + mpvPlayer.duration.toFixed(3) + "s"
            }

            Text {
                text: "FPS: " + mpvPlayer.fps.toFixed(2)
            }

            Text {
                text: "End Reached: " + mpvPlayer.endReached
                color: mpvPlayer.endReached ? "red" : "green"
            }
        }

        // File controls
        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "Load Video"
                onClicked: fileDialog.open()
            }

            Text {
                Layout.fillWidth: true
                text: mpvPlayer.filename || "No file loaded"
                elide: Text.ElideMiddle
            }
        }
    }

    // File dialog (simplified - you'd use a proper file dialog in real implementation)
    property string testVideoPath: "path/to/your/test/video.mp4"
    
    Component.onCompleted: {
        console.log("MPV Player initialized with new features:")
        console.log("- keep-open:", mpvPlayer.keepOpen)
        console.log("- hr-seek: enabled by default")
        console.log("- Available methods: seekToFirstFrame(), seekToLastFrame()")
    }
} 