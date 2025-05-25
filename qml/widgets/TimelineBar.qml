import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../utils"

// Smooth time-based timeline for precise video navigation
Item {
    id: root
    width: parent.width
    height: 40
    
    // Essential properties - time-based approach
    property var mpvObject: null
    property var timelineSync: null
    
    // Time-based properties (MPV official approach)
    property double currentPosition: 0.0  // Current time position in seconds
    property double duration: 0.0         // Total duration in seconds
    property real fps: 24.0
    property bool isPlaying: false
    
    // UI state
    property bool isDragging: false
    property double dragPosition: 0.0
    property bool seekInProgress: false
    
    // Visual settings
    property color backgroundColor: ThemeManager.timelineBackgroundColor
    property color trackColor: ThemeManager.timelineFrameColor
    property color activeTrackColor: ThemeManager.timelineActiveTrackColor
    property color playheadColor: ThemeManager.timelinePlayheadColor
    property color timecodeFontColor: "#FFFFFF"
    property int timecodeFontSize: 10
    property string timecodeFontFamily: "Consolas"
    
    // Signals
    signal seekRequested(double position)
    
    // Calculate playhead position based on current time
    property real playheadPosition: {
        if (duration <= 0) return 0;
        var pos = isDragging ? dragPosition : currentPosition;
        return Math.max(0, Math.min(width, (pos / duration) * width));
    }
    
    // Format time as HH:MM:SS.mmm
    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "00:00:00.000";
        
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        var secs = Math.floor(seconds % 60);
        var milliseconds = Math.floor((seconds % 1) * 1000);
        
        return hours.toString().padStart(2, '0') + ":" +
               minutes.toString().padStart(2, '0') + ":" +
               secs.toString().padStart(2, '0') + "." +
               milliseconds.toString().padStart(3, '0');
    }
    
    // Convert frame to time position
    function frameToTime(frame) {
        if (fps <= 0) return 0.0;
        return frame / fps;
    }
    
    // Convert time to frame
    function timeToFrame(time) {
        if (fps <= 0) return 0;
        return Math.round(time * fps);
    }
    
    // TimelineSync connection
    onTimelineSyncChanged: {
        if (timelineSync) {
            console.log("TimelineBar: TimelineSync connected");
            
            // Connect to position changes
            timelineSync.positionChanged.connect(function(position) {
                if (!isDragging) {
                    currentPosition = position;
                }
            });
            
            timelineSync.durationChanged.connect(function(newDuration) {
                duration = newDuration;
            });
            
            timelineSync.fpsChanged.connect(function(newFps) {
                fps = newFps;
            });
            
            timelineSync.playingStateChanged.connect(function(playing) {
                isPlaying = playing;
            });
        }
    }
    
    // Main timeline background
    Rectangle {
        id: timelineBackground
        anchors.fill: parent
        color: backgroundColor
        radius: 3
        
        // Timeline track
        Rectangle {
            id: timelineTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 5
            height: 6
            color: trackColor
            radius: 3
            
            // Active portion (played area)
            Rectangle {
                id: activeTrack
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: playheadPosition - 5
                color: activeTrackColor
                radius: 3
            }
        }
        
        // Time markers (every 10 seconds)
        Repeater {
            model: duration > 0 ? Math.floor(duration / 10) + 1 : 0
            
            Rectangle {
                x: (index * 10 / duration) * (width - 10) + 5
                y: timelineTrack.y - 5
                width: 1
                height: timelineTrack.height + 10
                color: Qt.lighter(trackColor, 1.5)
                visible: duration > 0
                
                // Time label
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 2
                    text: formatTime(index * 10).substring(0, 8) // HH:MM:SS only
                    color: timecodeFontColor
                    font.family: timecodeFontFamily
                    font.pixelSize: timecodeFontSize - 2
                    visible: (index * 10) % 30 === 0 // Show every 30 seconds
                }
            }
        }
        
        // Playhead
        Rectangle {
            id: playhead
            x: playheadPosition - width/2
            anchors.verticalCenter: timelineTrack.verticalCenter
            width: 12
            height: 12
            color: playheadColor
            radius: 6
            border.color: Qt.darker(playheadColor, 1.2)
            border.width: 1
            
            // Playhead line
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: playheadColor
            }
        }
        
        // Mouse interaction
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            
            onPressed: {
                isDragging = true;
                seekInProgress = true;
                
                // Calculate target position
                var targetPos = Math.max(0, Math.min(duration, (mouseX / width) * duration));
                dragPosition = targetPos;
                
                // Immediate seek for responsiveness
                performSeek(targetPos);
            }
            
            onPositionChanged: {
                if (pressed && isDragging) {
                    var targetPos = Math.max(0, Math.min(duration, (mouseX / width) * duration));
                    dragPosition = targetPos;
                    
                    // Throttled seeking during drag
                    seekThrottleTimer.restart();
                }
            }
            
            onReleased: {
                if (isDragging) {
                    isDragging = false;
                    
                    // Final precise seek
                    performSeek(dragPosition);
                    
                    // Update current position
                    currentPosition = dragPosition;
                    
                    seekInProgress = false;
                }
            }
        }
    }
    
    // Current time display
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 5
        width: currentTimeText.width + 10
        height: currentTimeText.height + 6
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 3
        
        Text {
            id: currentTimeText
            anchors.centerIn: parent
            text: formatTime(isDragging ? dragPosition : currentPosition)
            color: timecodeFontColor
            font.family: timecodeFontFamily
            font.pixelSize: timecodeFontSize
        }
    }
    
    // Duration display
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 5
        width: durationText.width + 10
        height: durationText.height + 6
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 3
        
        Text {
            id: durationText
            anchors.centerIn: parent
            text: formatTime(duration)
            color: timecodeFontColor
            font.family: timecodeFontFamily
            font.pixelSize: timecodeFontSize
        }
    }
    
    // Frame counter (optional)
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: 5
        width: frameText.width + 10
        height: frameText.height + 6
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 3
        visible: fps > 0
        
        Text {
            id: frameText
            anchors.centerIn: parent
            text: {
                var currentFrame = timeToFrame(isDragging ? dragPosition : currentPosition);
                var totalFrames = timeToFrame(duration);
                return currentFrame + " / " + totalFrames;
            }
            color: timecodeFontColor
            font.family: timecodeFontFamily
            font.pixelSize: timecodeFontSize - 1
        }
    }
    
    // Seek throttle timer
    Timer {
        id: seekThrottleTimer
        interval: 50 // 20fps update rate during drag
        repeat: false
        onTriggered: {
            if (isDragging) {
                performSeek(dragPosition);
            }
        }
    }
    
    // Perform time-based seek
    function performSeek(targetPosition) {
        if (!mpvObject || duration <= 0) return;
        
        try {
            console.log("TimelineBar: Time-based seek to position:", targetPosition);
            
            // Use TimelineSync if available (preferred)
            if (timelineSync) {
                timelineSync.seekToPosition(targetPosition, true);
            } else {
                // Direct MPV seek as fallback
                mpvObject.seekToPosition(targetPosition);
            }
            
            // Emit signal for other components
            seekRequested(targetPosition);
            
        } catch (e) {
            console.error("TimelineBar: Seek error:", e);
        }
    }
    
    // Keyboard navigation support
    Keys.onLeftPressed: {
        var newPos = Math.max(0, currentPosition - 1.0); // 1 second back
        performSeek(newPos);
    }
    
    Keys.onRightPressed: {
        var newPos = Math.min(duration, currentPosition + 1.0); // 1 second forward
        performSeek(newPos);
    }
    
    Keys.onUpPressed: {
        var newPos = Math.min(duration, currentPosition + 10.0); // 10 seconds forward
        performSeek(newPos);
    }
    
    Keys.onDownPressed: {
        var newPos = Math.max(0, currentPosition - 10.0); // 10 seconds back
        performSeek(newPos);
    }
} 