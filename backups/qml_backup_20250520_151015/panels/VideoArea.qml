import QtQuick
import QtQuick.Controls
import mpv 1.0

// Video area with professional styling
Item {
    id: videoArea
    
    // Properties
    property alias mpvPlayer: mpvObject
    property string currentMediaFile: ""
    property int currentFrame: 0
    property int totalFrames: 1000
    property real fps: 24.0
    property string currentTimecode: "00:00:00:00"
    
    // Debug rectangle to verify the component size and position
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "yellow"
        border.width: 2
        z: 5
    }
    
    // MPV video player
    MpvObject {
        id: mpvObject
        objectName: "mpvObject"
        anchors.fill: parent
        visible: true
        
        // Fix video rotation issue - 180 degree rotation
        transform: Rotation {
            origin.x: mpvObject.width/2
            origin.y: mpvObject.height/2
            angle: 180
        }
        
        // Custom property to track if position changed
        property real lastPosition: 0
        
        // Handler for realtime position changes during playback
        // This is critical for timeline synchronization
        Timer {
            interval: 16  // 60fps
            running: !mpvObject.pause && mpvObject.filename !== ""
            repeat: true
            onTriggered: {
                // Force a position check to update timeline
                let pos = mpvObject.getProperty("time-pos");
                if (pos !== undefined && pos !== null && Math.abs(pos - mpvObject.lastPosition) > 0.01) {
                    mpvObject.lastPosition = pos;
                    videoArea.parent.updateFrameInfo();
                }
            }
        }
        
        onFilenameChanged: {
            console.log("Filename changed to:", filename);
            lastPosition = 0;
        }
        
        onPauseChanged: {
            console.log("Pause state changed to:", pause);
            videoArea.parent.updateFrameInfo();
        }
        
        Component.onCompleted: {
            console.log("MPV 객체 초기화 완료!");
            try {
                console.log("MPV 객체 속성:", 
                            "width=", width, 
                            "height=", height,
                            "visible=", visible);
            } catch (e) {
                console.error("MPV 객체 초기화 중 오류:", e);
            }
        }
        
        // Additional MPV property change handlers
        onPositionChanged: {
            if (Math.abs(position - lastPosition) > 0.01) {
                lastPosition = position;
                videoArea.parent.updateFrameInfo();
            }
        }
        
        // Frame seek handler - optimized for performance during dragging
        onSeekRequested: function(frame) {
            if (mpvObject && typeof mpvObject.duration !== 'undefined' && mpvObject.duration > 0) {
                try {
                    // 1. 안전 범위 확인
                    var safeFrame = Math.max(0, Math.min(totalFrames - 50, frame));
                    
                    // 2. 프레임 위치 계산
                    var pos = safeFrame / fps;
                    
                    // 3. endReached 상태 초기화
                    if (mpvObject.endReached) {
                        mpvObject.resetEndReached();
                    }
                    
                    // 4. MPV 직접 시크 함수 호출
                    mpvObject.seekToPosition(pos);
                    
                    // 5. 현재 프레임 정보 업데이트
                    currentFrame = safeFrame;
                    
                    // 6. UI 강제 업데이트
                    videoArea.parent.updateFrameInfo();
                } catch (e) {
                    // console.error("Seek error:", e);
                }
            }
        }
    }
    
    // Video info overlay
    Rectangle {
        id: videoInfoOverlay
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10
        color: Qt.rgba(0, 0, 0, 0.7)
        width: videoInfoText.width + 20
        height: videoInfoText.height + 10
        radius: 3
        visible: mpvObject.filename !== ""
        
        Text {
            id: videoInfoText
            anchors.centerIn: parent
            text: currentMediaFile ? currentMediaFile.split('/').pop() : ""
            color: "white"
            font.pixelSize: 12
            font.family: "Consolas"
        }
    }
    
    // Timecode overlay
    Rectangle {
        id: timecodeOverlay
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        color: Qt.rgba(0, 0, 0, 0.7)
        width: timecodeText.width + 20
        height: timecodeText.height + 10
        radius: 3
        visible: mpvObject.filename !== ""
        
        Text {
            id: timecodeText
            anchors.centerIn: parent
            text: currentTimecode + " (" + currentFrame + "/" + totalFrames + ")"
            color: "white"
            font.pixelSize: 12
            font.family: "Consolas"
        }
    }
} 