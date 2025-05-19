import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mpv 1.0

// Media player controls component
Item {
    id: root
    width: parent.width
    height: 100
    
    // MPV player reference (set from parent)
    property var mpv

    // Time display formatting function
    function formatTime(seconds) {
        var hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)
        var secs = Math.floor(seconds % 60)
        
        return String(hours).padStart(2, '0') + ":" +
               String(minutes).padStart(2, '0') + ":" +
               String(secs).padStart(2, '0')
    }
    
    // Background gradient
    Rectangle {
        id: background
        anchors.fill: parent
        color: "#121214"
        
        // Bottom shadow gradient
        Rectangle {
            width: parent.width
            height: parent.height
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: "#80000000" }
                GradientStop { position: 1.0; color: "#D0000000" }
            }
        }
    }
    
    // Main control layout
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 10
        spacing: 10
        
        // Time display and progress bar
        Item {
            Layout.fillWidth: true
            height: 30
            
            // Time markers
            Row {
                id: timeMarkers
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 20
                spacing: (width - 8 * 80) / 7  // 8 markers evenly spaced
                
                Repeater {
                    model: 8
                    
                    Text {
                        required property int index
                        text: formatTime(index * ((mpv && mpv.duration > 0) ? mpv.duration / 7 : 0))
                        color: "#888888"
                        font.pixelSize: 11
                        width: 80
                        horizontalAlignment: index === 0 ? Text.AlignLeft : (index === 7 ? Text.AlignRight : Text.AlignHCenter)
                    }
                }
            }
            
            // Progress bar ticks
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: timeMarkers.bottom
                height: 10
                
                Repeater {
                    model: 8
                    
                    Rectangle {
                        required property int index
                        width: 1
                        height: 6
                        color: "#888888"
                        x: index * (parent.width - 1) / 7
                    }
                }
            }
        }
        
        // Progress/seek slider
        Slider {
            id: progressSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            from: 0
            to: mpv && mpv.duration > 0 ? mpv.duration : 100
            value: mpv ? mpv.position : 0
            
            // Update position when slider is moved
            onMoved: {
                if (mpv) {
                    mpv.position = value
                }
            }
            
            // Update slider when mpv position changes
            Connections {
                target: mpv
                function onPositionChanged() {
                    if (!progressSlider.pressed) {
                        progressSlider.value = mpv.position
                    }
                }
            }
            
            background: Rectangle {
                x: progressSlider.leftPadding
                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                width: progressSlider.availableWidth
                height: 4
                radius: 2
                color: "#333336"
                
                Rectangle {
                    width: progressSlider.visualPosition * parent.width
                    height: parent.height
                    color: "#3080FF"
                    radius: 2
                }
                
                // Current time marker
                Rectangle {
                    x: progressSlider.visualPosition * parent.width - width/2
                    y: -13
                    width: 1
                    height: 6
                    color: "#3080FF"
                    visible: progressSlider.value > 0
                }
                
                // Current time text
                Text {
                    x: Math.min(Math.max(progressSlider.visualPosition * parent.width - width/2, 0), parent.width - width)
                    y: -30
                    text: formatTime(progressSlider.value)
                    color: "white"
                    font.pixelSize: 12
                    visible: progressSlider.value > 0
                }
            }
            
            // Custom handle
            handle: Rectangle {
                x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: progressSlider.pressed ? "#40A0FF" : "#3080FF"
                
                // Scale effect when pressed
                scale: progressSlider.pressed ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                
                // 단순 테두리 효과
                border.color: "#30000000"
                border.width: 1
            }
        }
        
        // Controls row
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 10
            
            // Time display
            Text {
                id: timeText
                text: mpv ? formatTime(mpv.position) + " / " + formatTime(mpv.duration) : "00:00:00 / 00:00:00"
                color: "white"
                font.pixelSize: 13
                Layout.preferredWidth: 150
            }
            
            // Navigation buttons
            Row {
                spacing: 15
                Layout.alignment: Qt.AlignHCenter
                
                // Previous button
                Button {
                    id: prevButton
                    width: 36
                    height: 36
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: width / 2
                    }
                    
                    contentItem: Text {
                        text: "⏮"
                        color: parent.hovered ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("Previous button clicked")
                    }
                }
                
                // Backward button
                Button {
                    id: rewindButton
                    width: 36
                    height: 36
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: width / 2
                    }
                    
                    contentItem: Text {
                        text: "⏪"
                        color: parent.hovered ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("Rewind button clicked")
                        if (mpv && mpv.position >= 10) {
                            mpv.position -= 10
                        }
                    }
                }
                
                // Play/Pause button
                Button {
                    id: playButton
                    width: 50
                    height: 50
                    
                    background: Rectangle {
                        color: "#3080FF"
                        radius: width / 2
                        
                        // 단순 테두리 효과
                        border.color: "#30000000"
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: mpv && mpv.playing ? "⏸" : "▶"
                        color: "white"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("Play/Pause button clicked")
                        if (mpv) {
                            mpv.playPause()
                        }
                    }
                    
                    // Add mouseArea to ensure clicks are caught
                    MouseArea {
                        anchors.fill: parent
                        onPressed: function(mouse) {
                            console.log("Play/Pause button pressed via MouseArea")
                            mouse.accepted = false // Pass the event through to Button
                        }
                    }
                }
                
                // Forward button
                Button {
                    id: forwardButton
                    width: 36
                    height: 36
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: width / 2
                    }
                    
                    contentItem: Text {
                        text: "⏩"
                        color: parent.hovered ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("Forward button clicked")
                        if (mpv && mpv.duration > 0) {
                            mpv.position = Math.min(mpv.position + 10, mpv.duration)
                        }
                    }
                }
                
                // Next button
                Button {
                    id: nextButton
                    width: 36
                    height: 36
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: width / 2
                    }
                    
                    contentItem: Text {
                        text: "⏭"
                        color: parent.hovered ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("Next button clicked")
                    }
                }
            }
            
            // Right side controls
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignRight
                
                // Volume label
                Text {
                    text: mpv ? Math.round(mpv.volume) + "%" : "100%"
                    color: "white"
                    font.pixelSize: 12
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
                
                // Volume slider
                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 100
                    from: 0
                    to: 100
                    value: mpv ? mpv.volume : 100
                    
                    onMoved: {
                        if (mpv) {
                            mpv.volume = value
                        }
                    }
                    
                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: volumeSlider.availableWidth
                        height: 4
                        radius: 2
                        color: "#333336"
                        
                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#3080FF"
                            radius: 2
                        }
                    }
                    
                    // Custom handle
                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 12
                        implicitHeight: 12
                        radius: 6
                        color: volumeSlider.pressed ? "#40A0FF" : "#3080FF"
                        
                        // 단순 테두리 효과
                        border.color: "#30000000"
                        border.width: 1
                    }
                }
                
                // Mute button
                Button {
                    id: muteButton
                    width: 32
                    height: 32
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: width / 2
                    }
                    
                    contentItem: Text {
                        text: mpv && mpv.muted ? "🔇" : "🔊"
                        color: parent.hovered ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("Mute button clicked")
                        if (mpv) {
                            mpv.muted = !mpv.muted
                        }
                    }
                }
                
                // Fullscreen button
                Button {
                    id: fullscreenButton
                    width: 32
                    height: 32
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: width / 2
                    }
                    
                    contentItem: Text {
                        text: "⛶"
                        color: parent.hovered ? "#FFFFFF" : "#AAAAAA"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("Fullscreen button clicked")
                        // The fullscreen logic is in the main window
                    }
                }
            }
        }
    }
} 