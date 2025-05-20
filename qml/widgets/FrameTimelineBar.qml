import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../utils"

// Frame-accurate timeline for precise frame navigation
Item {
    id: root
    width: parent.width
    height: 40
    
    // Essential properties
    property var mpvObject: null // MPV 플레이어 객체
    property int currentFrame: 0
    property int totalFrames: 100
    property real fps: 24.0
    property bool isPlaying: false
    
    // Signal when user requests to seek to a specific frame
    signal seekRequested(int frame)
    
    // Frame visualization settings
    property int majorFrameInterval: 5  // Show bigger marker every N frames
    property int timecodeInterval: Math.max(10, Math.floor(fps))  // Show timecode every N frames
    
    // Colors and styling
    property color backgroundColor: "#1E1E1E"
    property color frameColor: "#444444"
    property color majorFrameColor: "#777777"
    property color playheadColor: "#FF4444"
    property color activeTrackColor: "#2277FF"
    property color timecodeFontColor: "#FFFFFF"
    property int timecodeFontSize: 9
    property string timecodeFontFamily: "Consolas"

    // Calculate timeline dimensions to always fill width
    property real frameSpacing: Math.max(2, width / Math.max(1, totalFrames))
    property real scaleFactor: width / Math.max(1, totalFrames)
    
    // Track state
    property bool isDragging: false
    property int dragFrame: 0  // Store the exact frame being dragged to
    property int lastSentFrame: -1  // Track the last frame we sent for seeking
    property bool throttleSeeking: true  // Throttle seeking while dragging for better performance
    
    // Direct playhead position tracking
    property real playheadPosition: getExactFramePosition(currentFrame)
    property bool seekInProgress: false  // 시크 작업 진행 중 플래그
    
    // 프레임 카운터 표시 계산
    property int displayOffset: (mpvObject && mpvObject.oneBasedFrameNumbers) ? 1 : 0
    property string frameCounterText: {
        if (isDragging) {
            return (dragFrame + displayOffset) + " / " + (totalFrames ? (totalFrames + displayOffset - 1) : 0);
        } else {
            return (currentFrame + displayOffset) + " / " + (totalFrames ? (totalFrames + displayOffset - 1) : 0);
        }
    }
    
    // Snap playhead position to exact frame
    function getExactFramePosition(frame) {
        // totalFrames가 유효하지 않은 경우 방어 코드 추가
        if (totalFrames <= 0) return 0;
        
        // 안전하게 프레임 범위 제한
        var safeFrame = Math.max(0, Math.min(frame, totalFrames - 5));
        return Math.round(safeFrame * scaleFactor - 1);
    }
    
    // 강제로 플레이헤드 위치 업데이트 타이머
    Timer {
        id: forceUpdateTimer
        interval: 33  // ~30fps (더 안정적인 값으로 변경)
        repeat: true
        running: isPlaying || seekInProgress // 재생 중이거나 시크 중일 때 플레이헤드 위치 강제 업데이트
        onTriggered: {
            // 현재 프레임 위치에 맞게 플레이헤드 위치 강제 업데이트
            if (!isDragging) {
                // 드래그 중이 아닐 때만 업데이트
                playheadPosition = getExactFramePosition(currentFrame);
                playhead.x = playheadPosition;
            }
        }
    }
    
    // 프레임 정밀 시크 함수 - 영상 끝 부분 문제 해결
    function preciseFrameSeek(frame, exact) {
        // MPV가 없거나 영상 길이가 없을 경우 무시
        if (!mpvObject || typeof mpvObject.duration === 'undefined' || mpvObject.duration <= 0) return;
        
        // 프레임 범위 확인 - 안전하게 처리
        var safeFrame = Math.max(0, Math.min(frame, totalFrames - 30));
        
        try {
        // 프레임을 시간 위치로 변환
            var pos = safeFrame / fps;
        
            // 끝부분에서의 시크 처리
            var isTooCloseToEnd = (totalFrames - safeFrame) < 30;
        
        // 현재 프레임 즉시 업데이트 (UI 반응성)
            currentFrame = safeFrame;
            
            // 상태 변수 설정 - 중복 시크 방지
            seekInProgress = true;
            
            // 시크 시 endReached 상태 초기화
            if (mpvObject.endReached) {
                mpvObject.resetEndReached();
            }
        
            // MPV 명령 실행 - 끝부분에서는 안전 모드 사용
            if (isTooCloseToEnd) {
                // 끝 부분에 가까울 때는 더 안전한 위치로 시크
                var safePos = Math.max(0, mpvObject.duration - 0.5);
                mpvObject.command(["seek", safePos, "absolute", "exact"]);
                
                // 항상 일시 정지 상태 유지
                mpvObject.command(["set_property", "pause", "yes"]);
                
                // 빠른 검증 수행
                verifySeekTimer.interval = 50;
                verifySeekTimer.restart();
            } else if (exact) {
                mpvObject.command(["seek", pos, "absolute", "exact"]);
                verifySeekTimer.interval = 80;
                verifySeekTimer.restart();
            } else {
                mpvObject.command(["seek", pos, "absolute", "exact"]);
                verifySeekTimer.interval = 60;
                verifySeekTimer.restart();
            }
            
            // 플레이헤드 위치 즉시 업데이트
            playheadPosition = getExactFramePosition(safeFrame);
                    playhead.x = playheadPosition;
        } catch (e) {
            // console.error("시크 중 오류:", e);
            seekInProgress = false;
        }
    }
    
    // 시크 후 검증 타이머 - 더 강력한 동기화
    Timer {
        id: verifySeekTimer
        interval: 80
        repeat: false
        onTriggered: {
            try {
                // 1. 최종 시크 후 실제 위치 다시 확인
                if (mpvObject) {
                    var finalPos = mpvObject.getProperty("time-pos");
            if (finalPos !== undefined && finalPos !== null) {
                        var finalFrame = Math.round(finalPos * fps);
                        // 계산된 프레임과 현재 프레임이 다른 경우 한 번 더 동기화
                        if (finalFrame !== currentFrame && Math.abs(finalFrame - currentFrame) > 1) {
                            // 타임라인 끝 부분이면 강제 조정하지 않음
                            if (currentFrame < totalFrames - 20) {
                    currentFrame = finalFrame;
                                playheadPosition = getExactFramePosition(finalFrame);
                    playhead.x = playheadPosition;
                }
                        }
                    }
            }
            
                // 2. 시크 완료 처리
            seekInProgress = false;
            } catch (e) {
                // console.error("시크 검증 오류:", e);
                seekInProgress = false;
            }
        }
    }
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: ThemeManager.timelineBackgroundColor
        border.color: ThemeManager.borderColor
        border.width: 1
    }
    
    // Frame markers container
    Item {
        id: timelineContent
        anchors.fill: parent
        clip: true // Prevent drawing outside bounds
        
        // Draw all frame markers using Canvas for better performance
        Canvas {
            id: frameMarkers
            anchors.fill: parent
            
            // Use layer for hardware acceleration where available
            layer.enabled: true
            layer.samples: 2  // 샘플링 수 감소 (성능 향상)
            
            // 캔버스 렌더링 속도 향상을 위한 최적화
            renderStrategy: Canvas.Cooperative 
            renderTarget: Canvas.FramebufferObject
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                
                // Don't draw anything if totalFrames isn't valid yet
                if (totalFrames <= 0) return;
                
                var height = frameMarkers.height;
                var displayWidth = width;
                
                // Calculate spacing to fill the entire width
                var spacing = displayWidth / totalFrames;
                
                // Optimize rendering - only draw visible markers
                // This drastically improves performance for long videos
                var visibleFramesPerPixel = totalFrames / displayWidth;
                
                // If we have more frames than pixels, we need to be selective about what we draw
                if (visibleFramesPerPixel > 1) {
                    // Draw reduced number of markers for performance
                    var stepSize = Math.max(1, Math.floor(visibleFramesPerPixel));
                    
                    for (var i = 0; i < totalFrames; i += stepSize) {
                        var x = i * spacing;
                        
                        // Draw major frame markers
                        if (i % majorFrameInterval === 0) {
                            ctx.strokeStyle = ThemeManager.timelineMajorFrameColor;
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            ctx.moveTo(x, 0);
                            ctx.lineTo(x, height * 0.7);
                            ctx.stroke();
                            
                            // Add timecode for major frame intervals - but less frequently for performance
                            if (i % (timecodeInterval * 2) === 0) {
                                ctx.fillStyle = "white";
                                ctx.font = timecodeFontSize + "px " + timecodeFontFamily;
                                ctx.textAlign = "center";
                                ctx.fillText((i + displayOffset).toString(), x, height * 0.4);
                            }
                        }
                    }
                } else {
                    // We have fewer frames than pixels, can draw all markers
                    for (var i = 0; i < totalFrames; i++) {
                        var x = i * spacing;
                        
                        // 성능을 위해 모든 프레임을 그리지 않고 선택적으로 그림
                        if (i % 2 === 0) {
                        // Draw frame marker
                        if (i % majorFrameInterval === 0) {
                            // Major frame (taller line)
                            ctx.strokeStyle = ThemeManager.timelineMajorFrameColor;
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            ctx.moveTo(x, 0);
                            ctx.lineTo(x, height * 0.7);
                            ctx.stroke();
                        } else {
                            // Regular frame
                            ctx.strokeStyle = ThemeManager.timelineFrameColor;
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            ctx.moveTo(x, height * 0.5);
                            ctx.lineTo(x, height * 0.7);
                            ctx.stroke();
                        }
                        }
                        
                        // Add timecode for major frames - less often for performance
                        if (i % timecodeInterval === 0 && i % 2 === 0) {
                            // Draw timecode text with offset for display
                            ctx.fillStyle = "white";
                            ctx.font = timecodeFontSize + "px " + timecodeFontFamily;
                            ctx.textAlign = "center";
                            ctx.fillText((i + displayOffset).toString(), x, height * 0.4);
                        }
                    }
                }
            }
        }
        
        // Current frame playhead - direct position control without animations
        Rectangle {
            id: playhead
            x: playheadPosition
            width: 2
            height: parent.height * 0.85
            y: 0
            color: ThemeManager.timelinePlayheadColor
            visible: !isDragging
            
            // Triangle pointer at the bottom of the playhead
            Canvas {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 10
                height: 5
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = parent.color;
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(width, 0);
                    ctx.lineTo(width/2, height);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }
        
        // Drag handle (shown during dragging)
        Rectangle {
            id: dragHandle
            x: isDragging ? getExactFramePosition(dragFrame) : getExactFramePosition(currentFrame)
            width: 2
            height: parent.height * 0.85
            y: 0
            color: ThemeManager.accentColor
            visible: isDragging
            
            // Triangle pointer at the bottom
            Canvas {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 10
                height: 5
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = parent.color;
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(width, 0);
                    ctx.lineTo(width/2, height);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }
    }
    
    // Frame indicator text
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        color: Qt.rgba(0, 0, 0, 0.5)
        width: frameCounterDisplay.width + 10
        height: frameCounterDisplay.height + 4
        radius: 2
        
        Text {
            id: frameCounterDisplay
            anchors.centerIn: parent
            text: frameCounterText
            color: "white"
            font.family: timecodeFontFamily
            font.pixelSize: 10
        }
    }
    
    // Mouse handling for timeline interaction - 드래그 핵심 코드 최적화
    MouseArea {
        anchors.fill: parent
        
        onPressed: {
            try {
                // 1. 드래그 시작
            isDragging = true;
                
                // 2. 정확한 좌표 계산 (범위 제한 적용)
                var clampedX = Math.min(Math.max(0, mouseX), width);
                var frameFraction = clampedX / scaleFactor;
                dragFrame = Math.min(Math.max(0, Math.round(frameFraction)), Math.max(1, totalFrames - 50));
                
                // 3. 드래그 핸들 UI 업데이트
                dragHandle.x = getExactFramePosition(dragFrame);
                
                // 4. 현재 프레임 즉시 업데이트 (지연 없이)
                currentFrame = dragFrame;
            
                // 5. endReached 상태 초기화
                if (mpvObject && mpvObject.endReached) {
                    mpvObject.resetEndReached();
                }
                
                // 상태 플래그 설정
                seekInProgress = true;
            } catch (e) {
                // console.error("드래그 시작 오류:", e);
                isDragging = false;
                seekInProgress = false;
            }
        }
        
        onPositionChanged: {
            if (isDragging) {
                try {
                    // 1. 안전한 좌표 범위 계산
                    var clampedX = Math.min(Math.max(0, mouseX), width);
                    
                    // 2. 정확한 프레임 계산
                    var frameFraction = clampedX / scaleFactor;
                    var newDragFrame = Math.min(Math.max(0, Math.round(frameFraction)), Math.max(1, totalFrames - 50));
                
                    // 3. 프레임이 실제로 변경된 경우에만 처리
                    if (newDragFrame !== dragFrame) {
                        // 드래그 프레임 업데이트
                        dragFrame = newDragFrame;
                        
                        // 드래그 핸들 UI 업데이트
                        dragHandle.x = getExactFramePosition(dragFrame);
                        
                        // 현재 프레임 업데이트
                        currentFrame = dragFrame;
                        
                        // 디바운스 설정
                        if (!seekDebounceTimer.running) {
                            seekDebounceTimer.restart();
                    }
                    }
                } catch (e) {
                    // console.error("드래그 중 오류:", e);
                }
            }
        }
        
        onReleased: {
            if (isDragging) {
                try {
                    // console.log("실행: 드래그 완료, 최종 프레임:", dragFrame);
                
                    // 1. 정확한 시간 위치 계산
                    var pos = dragFrame / fps;
                
                    // 2. 안전한 범위 계산
                    if (mpvObject && mpvObject.duration > 0) {
                        // 3. MPV로 직접 시크 요청
                        mpvObject.seekToPosition(pos);
                    }
                    
                    // 4. 드래그 상태 초기화
                isDragging = false;
                
                    // 5. 검증 타이머 시작
                    verifySeekTimer.restart();
                } catch (e) {
                    // console.error("드래그 종료 오류:", e);
                    isDragging = false;
                    seekInProgress = false;
                }
            }
        }
    }
    
    // 시크 디바운스 타이머 - 개선
    Timer {
        id: seekDebounceTimer
        interval: 80  // 약간 더 높은 지연 (안정성)
        repeat: false
        onTriggered: {
            if (isDragging && mpvObject) {
                try {
                    // console.log("실행: 드래그 중 시크, 프레임:", dragFrame);
                    
                    // 정확한 시간 위치 계산
                    var pos = dragFrame / fps;
                    
                    // MPV 명령 직접 사용하여 즉시 시크 (UI 업데이트 목적)
                    mpvObject.command(["seek", pos, "absolute", "exact"]);
                
                    // 현재 위치 정보 업데이트
                    var framesPerSecond = fps > 0 ? fps : 24.0;
                    var frame = Math.round(pos * framesPerSecond);
                    currentFrame = frame;
                } catch (e) {
                    // console.error("디바운스 시크 오류:", e);
                }
            }
        }
    }
    
    // Update display when properties change
    onTotalFramesChanged: {
        frameMarkers.requestPaint();
    }
    
    onWidthChanged: {
        frameMarkers.requestPaint();
    }
    
    onFpsChanged: {
        timecodeInterval = Math.max(10, Math.floor(fps));
        frameMarkers.requestPaint();
    }
    
    // 현재 프레임이 변경될 때 강제 업데이트 - 더 안정적인 동기화
    onCurrentFrameChanged: {
        if (!isDragging) {
            try {
                // 프레임 위치 계산 및 UI 강제 업데이트
            playheadPosition = getExactFramePosition(currentFrame);
            playhead.x = playheadPosition;
            } catch (e) {
                // console.error("프레임 변경 처리 오류:", e);
            }
        }
        frameMarkers.requestPaint();
    }
    
    // 프레임 번호 체계에 따라 업데이트
    onDisplayOffsetChanged: {
        frameMarkers.requestPaint();
    }
    
    Component.onCompleted: {
        frameMarkers.requestPaint();
    }
} 