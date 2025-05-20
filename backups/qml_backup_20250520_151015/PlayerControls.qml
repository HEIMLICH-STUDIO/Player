import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Rectangle {
    id: playerControls
    color: "#1E1E1E"
    height: 40
    
    property bool isPlaying: false
    property real volume: 1.0
    property bool isMuted: false
    
    signal playPauseClicked()
    signal stopClicked()
    signal previousClicked()
    signal nextClicked()
    signal seekBackward()
    signal seekForward()
    signal volumeChanged(real newVolume)
    signal muteToggled(bool muted)
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8
        
        MediaControlButton {
            iconName: "play"
            onClicked: playPauseClicked()
        }
        
        MediaControlButton {
            iconName: "stop" 
            onClicked: stopClicked()
        }
        
        MediaControlButton {
            iconName: "rewind"
            onClicked: previousClicked()
        }
        
        MediaControlButton {
            iconName: "fast_forward"
            onClicked: nextClicked()
        }
        
        Item { Layout.fillWidth: true }
        
        Slider {
            id: volumeSlider
            Layout.preferredWidth: 100
            from: 0
            to: 1.0
            value: volume
            
            onMoved: {
                volumeChanged(value)
            }
        }
        
        MediaControlButton {
            iconName: isMuted ? "volume" : "mute"
            onClicked: muteToggled(!isMuted)
        }
    }
} 