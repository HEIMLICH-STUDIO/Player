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
    
    // 양방향 바인딩 개선을 위한 핵심 변경사항
    property int currentFrame: 0
    
    // 정밀한 제어를 위한 내부 프레임 프로퍼티
    property int _internalFrame: 0
    
    property int totalFrames: 0
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
    property color activeTrackColor: "#780000"
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
    property bool recentlyDragged: false  // 드래그 후 안정화 기간 플래그
    
    // 플레이헤드 직접 위치 결정 (외부에서 설정된 값이 있으면 우선 사용)
    property real playheadPosition: getExactFramePosition(_internalFrame)
    property bool seekInProgress: false  // 시크 작업 진행 중 플래그
    
    // 프레임 카운터 표시 계산
    property int displayOffset: (mpvObject && mpvObject.oneBasedFrameNumbers) ? 1 : 0
    property string frameCounterText: {
        if (isDragging) {
            return (dragFrame + displayOffset) + " / " + (totalFrames ? (totalFrames + displayOffset - 1) : 0);
        } else {
            return (_internalFrame + displayOffset) + " / " + (totalFrames ? (totalFrames + displayOffset - 1) : 0);
        }
    }
    
    // 양방향 바인딩을 위한 핵심 변경사항
    // 외부 프레임이 변경되면 내부 프레임도 업데이트
    onCurrentFrameChanged: {
        if (!isDragging && currentFrame !== _internalFrame) {
            console.log("타임라인: 외부 프레임 변경 감지:", currentFrame);
            _internalFrame = currentFrame;
            updatePlayhead();
        }
    }
    
    // 내부 프레임이 변경되면 외부 프레임에 알리고 플레이헤드 위치 업데이트
    on_InternalFrameChanged: {
        // 내부 프레임이 변경되면 플레이헤드 업데이트
        updatePlayhead();
        
        // 드래그 중이 아니고 현재 프레임과 차이가 있을 때만 외부에 알림
        if (!isDragging && _internalFrame !== currentFrame) {
            // 여기서 바로 currentFrame을 업데이트하지 않고 신호로 보냄
            seekRequested(_internalFrame);
        }
    }
    
    // Centralized function to update the playhead
    function updatePlayhead() {
        if (!isDragging) {
            // 플레이헤드 위치를 직접 계산하여 설정
            var exactPosition = getExactFramePosition(_internalFrame);
            if (playhead.x !== exactPosition) {
                playhead.x = exactPosition;
            }
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
    
    // 내부 상태 초기화 (강제 동기화 시 사용)
    function resetInternalState() {
        if (mpvObject) {
            try {
                // MPV에서 현재 위치 가져오기
                var timePos = mpvObject.getProperty("time-pos");
                if (timePos !== undefined && timePos !== null) {
                    // 현재 프레임 계산
                    var mpvFrame = Math.round(timePos * fps);
                    
                    // 내부 상태 업데이트
                    _internalFrame = mpvFrame;
                    
                    // 플레이헤드 강제 업데이트
                    updatePlayhead();
                    
                    // 로그
                    console.log("타임라인: 내부 상태 초기화 - 프레임:", mpvFrame);
                }
            } catch (e) {
                console.error("내부 상태 초기화 오류:", e);
            }
        }
    }
    
    // 강제로 플레이헤드 위치 업데이트 타이머
    Timer {
        id: forceUpdateTimer
        interval: 100  // 더 빠른 업데이트 (100ms, 10fps)
        repeat: true
        running: isPlaying || seekInProgress // 재생 중이거나 시크 중일 때 플레이헤드 위치 강제 업데이트
        onTriggered: {
            // 현재 프레임 위치에 맞게 플레이헤드 위치 강제 업데이트
            if (!isDragging) {
                // MPV와 현재 프레임 동기화 확인
                if (mpvObject) {
                    try {
                        var timePos = mpvObject.getProperty("time-pos");
                        if (timePos !== undefined && timePos !== null) {
                            var mpvFrame = Math.round(timePos * fps);
                            
                            // MPV와 내부 프레임이 크게 다르면 동기화
                            if (Math.abs(mpvFrame - _internalFrame) > 1) {
                                console.log("강제 업데이트: MPV 프레임=", mpvFrame, "내부 프레임=", _internalFrame);
                                _internalFrame = mpvFrame;
                            }
                        }
                    } catch (e) {
                        // 오류 무시 (타이머에서 발생)
                    }
                }
                
                // 플레이헤드 위치 업데이트
                updatePlayhead();
            }
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
                        console.log("검증: MPV 프레임=", finalFrame, "_internalFrame=", _internalFrame);
                        
                        // 계산된 프레임과 현재 프레임이 다른 경우 한 번 더 동기화
                        if (finalFrame !== _internalFrame && Math.abs(finalFrame - _internalFrame) > 1) {
                            console.log("프레임 불일치 감지 - 동기화 수행");
                            
                            // 내부 프레임 업데이트
                            _internalFrame = finalFrame;
                            updatePlayhead();
                            
                            // 이 프레임 위치로 다시 시크 요청 (영상 동기화 보장)
                            var pos = finalFrame / fps;
                            mpvObject.command(["seek", pos, "absolute", "exact"]);
                            
                            // 상위 컴포넌트에 알림 (이중 업데이트 방지)
                            if (Math.abs(finalFrame - currentFrame) > 1) {
                                seekRequested(finalFrame);
                            }
                        }
                    }
                }
            
                // 2. 시크 완료 처리
                seekInProgress = false;
            } catch (e) {
                console.error("시크 검증 오류:", e);
                seekInProgress = false;
            }
        }
    }
    
    // 시크 디바운스 타이머 - MPV 명령 최적화
    Timer {
        id: seekDebounceTimer
        interval: 40  // 더 빠른 응답성
        repeat: false
        onTriggered: {
            if (isDragging && mpvObject) {
                try {
                    console.log("드래그 중 시크 (디바운스), 프레임:", dragFrame);
                    
                    // 정확한 시간 위치 계산
                    var pos = dragFrame / fps;
                    
                    // 강력한 시크 구현
                    // 1. 직접 속성 설정 (최고 속도)
                    mpvObject.setProperty("time-pos", pos);
                    
                    // 2. 명령어 인터페이스 사용 (정확도)
                    mpvObject.command(["seek", pos.toString(), "absolute", "exact"]);
                    
                    // 3. 일시 정지 상태 확인
                    if (!isPlaying) {
                        mpvObject.setProperty("pause", true);
                    }
                    
                    // 4. UI 업데이트
                    _internalFrame = dragFrame;
                    updatePlayhead();
                    
                    // 5. 시그널 발생 (상위 알림)
                    seekRequested(dragFrame);
                    
                    // 6. 상태 로그
                    console.log("MPV 시크 적용 완료, 프레임:", dragFrame, "시간:", pos);
                } catch (e) {
                    console.error("디바운스 시크 오류:", e);
                }
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
                
                // 4. 내부 프레임 즉시 업데이트 (지연 없이) - 바인딩 유지
                _internalFrame = dragFrame;
                
                // 5. endReached 상태 초기화
                if (mpvObject && mpvObject.endReached) {
                    mpvObject.resetEndReached();
                }
                
                // 6. MPV 직접 시크 명령 - 최우선 (강제 적용)
                if (mpvObject) {
                    try {
                        var pos = dragFrame / fps;
                        
                        // 첫번째 시크: 속성 직접 설정 (즉각 적용)
                        mpvObject.setProperty("time-pos", pos);
                        
                        // 두번째 시크: 명령 인터페이스 (정확도 향상)
                        mpvObject.command(["seek", pos.toString(), "absolute", "exact"]);
                        
                        // 일시 정지 상태 확인
                        if (!isPlaying) {
                            mpvObject.setProperty("pause", true);
                        }
                        
                        // 로그 출력
                        console.log("드래그 시작 시크 명령 전송 - 프레임:", dragFrame, "시간:", pos);
                        
                        // 7. 시그널 발생 (상위 객체에 알림)
                        seekRequested(dragFrame);
                    } catch (e) {
                        console.error("MPV 시크 명령 오류:", e);
                    }
                }
                
                // 상태 플래그 설정
                seekInProgress = true;
            } catch (e) {
                console.error("드래그 시작 오류:", e);
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
                        
                        // 내부 프레임 즉시 업데이트
                        _internalFrame = dragFrame;
                        
                        // MPV에 즉각적인 업데이트 (즉시 피드백)
                        if (mpvObject) {
                            try {
                                var pos = dragFrame / fps;
                                
                                // UI 즉각 반응을 위한 속성 직접 설정
                                mpvObject.setProperty("time-pos", pos);
                                
                                // 로그 출력
                                console.log("드래그 중 즉시 업데이트 - 프레임:", dragFrame);
                            } catch (e) {
                                // 드래그 중 오류는 무시 (성능 위해)
                            }
                        }
                        
                        // 디바운스 설정 - 더 빠른 응답을 위해 인터벌 축소
                        if (!seekDebounceTimer.running) {
                            seekDebounceTimer.interval = 40; // 더 빠른 응답
                            seekDebounceTimer.restart();
                        }
                    }
                } catch (e) {
                    console.error("드래그 중 오류:", e);
                }
            }
        }
        
        onReleased: {
            if (isDragging) {
                try {
                    console.log("드래그 완료, 최종 프레임:", dragFrame);
                
                    // 1. 정확한 시간 위치 계산
                    var pos = dragFrame / fps;
                
                    // 2. 안전한 범위 계산
                    if (mpvObject && mpvObject.duration > 0) {
                        // 3. MPV로 강력한 직접 시크 명령 송출
                        // 3.1 속성 직접 설정 (최우선)
                        mpvObject.setProperty("time-pos", pos);
                        
                        // 3.2 시크 명령 전송 (정확도 향상)
                        mpvObject.command(["seek", pos, "absolute", "exact"]);
                        
                        // 이전 위치에서 새 위치로 강제 시크 (최종 보장)
                        var currentPos = mpvObject.getProperty("time-pos");
                        if (currentPos !== undefined && currentPos !== null) {
                            if (Math.abs(currentPos - pos) > 0.01) {
                                // 차이가 있으면 다시 시크
                                console.log("위치 차이 발견, 재시크 - 현재:", currentPos, "목표:", pos);
                                mpvObject.setProperty("time-pos", pos);
                                mpvObject.command(["seek", pos, "absolute", "exact"]);
                            }
                        }
                        
                        // 일시 정지 상태 확인
                        if (!isPlaying) {
                            mpvObject.setProperty("pause", true);
                        }
                        
                        // 4. 내부 프레임 업데이트 - 먼저
                        _internalFrame = dragFrame;
                        
                        // 5. 상위 컴포넌트에 알림 - 중요: 강제로 현재 프레임을 업데이트
                        currentFrame = dragFrame; // 직접 현재 프레임 업데이트
                        
                        // 6. 시그널 발생 (추가)
                        seekRequested(dragFrame);
                    }
                    
                    // 7. 드래그 상태 초기화
                    isDragging = false;
                    
                    // 8. 드래그 후 안정화 플래그 설정 및 타이머 시작
                    recentlyDragged = true;
                    dragStabilizationTimer.restart();
                    console.log("드래그 안정화 타이머 시작 - 다음 800ms 동안 MPV 싱크 이벤트 무시");
                
                    // 9. 검증 타이머 시작 (더 길게 설정)
                    verifySeekTimer.interval = 100;
                    verifySeekTimer.restart();
                    
                    // 10. 강제 동기화 타이머
                    forceUpdateTimer.restart();
                    
                    // 11. 복구 타이머 시작
                    recoveryTimer.interval = 150;
                    recoveryTimer.restart();
                    
                    // 12. MPV 동기화를 위한 두 번째 시크
                    secondSyncTimer.start();
                    
                    // 13. 최종 확인
                    finalSyncTimer.dragFrame = dragFrame;
                    finalSyncTimer.start();
                } catch (e) {
                    console.error("드래그 종료 오류:", e);
                    isDragging = false;
                    seekInProgress = false;
                }
            }
        }
    }
    
    // 두 번째 동기화 타이머 (Qt.setTimeout 대체)
    Timer {
        id: secondSyncTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (mpvObject && mpvObject.duration > 0) {
                // 한 번 더 시크 명령 전송 (확실한 적용을 위해)
                var pos = dragFrame / fps;
                mpvObject.seekToPosition(pos);
            }
        }
    }
    
    // 바인딩 복원 타이머 - 드래그 후 동기화 처리
    Timer {
        id: recoveryTimer
        interval: 200
        repeat: false
        onTriggered: {
            try {
                if (!isDragging && mpvObject) {
                    var timePos = mpvObject.getProperty("time-pos");
                    if (timePos !== undefined && timePos !== null) {
                        // 현재 프레임 동기화 (내부만)
                        var mpvFrame = Math.round(timePos * fps);
                        console.log("복구: MPV 프레임=", mpvFrame, "_internalFrame=", _internalFrame);
                        
                        // 차이가 크면 완전히 다시 동기화
                        if (Math.abs(mpvFrame - _internalFrame) > 1) {
                            console.log("프레임 불일치 복구 - 강제 동기화 수행");
                            
                            // 1. 내부 프레임 업데이트
                            _internalFrame = mpvFrame;
                            updatePlayhead();
                            
                            // 2. MPV 포지션으로 명시적 시크 다시 수행
                            mpvObject.command(["seek", timePos, "absolute", "exact"]);
                            
                            // 3. 상위 객체에 알림 (중요: 영상과 UI 완전 동기화)
                            if (Math.abs(mpvFrame - currentFrame) > 1) {
                                seekRequested(mpvFrame);
                            }
                            
                            console.log("복구 완료: 최종 프레임=", mpvFrame);
                        }
                    }
                }
            } catch (e) {
                console.error("Timeline recovery error:", e);
            }
        }
    }
    
    // 최종 동기화 검증 타이머 (드래그 완료 후 300ms)
    Timer {
        id: finalSyncTimer
        interval: 300
        repeat: false
        property int dragFrame: 0
        
        onTriggered: {
            if (mpvObject) {
                try {
                    // 현재 실제 MPV 위치 확인
                    var timePos = mpvObject.getProperty("time-pos");
                    var currentMpvFrame = Math.round(timePos * fps);
                    
                    // UI 프레임과 큰 차이가 있는지 확인
                    var targetFrame = dragFrame;
                    if (Math.abs(currentMpvFrame - targetFrame) > 1) {
                        console.log("최종 동기화: 불일치 감지 -", currentMpvFrame, "vs", targetFrame);
                        
                        // 한 번 더 강제 시크
                        var pos = targetFrame / fps;
                        mpvObject.setProperty("time-pos", pos);
                        mpvObject.command(["seek", pos, "absolute", "exact"]);
                        
                        // 상위 객체에도 알림
                        seekRequested(targetFrame);
                    }
                } catch (e) {
                    console.error("최종 동기화 오류:", e);
                }
            }
        }
    }
    
    // 드래그 안정화 타이머 - 드래그 후 MPV 싱크 이벤트를 일시적으로 차단함
    Timer {
        id: dragStabilizationTimer
        interval: 800  // 드래그 후 800ms 동안 MPV 싱크 이벤트 무시
        repeat: false
        onTriggered: {
            recentlyDragged = false;
            console.log("드래그 안정화 기간 종료");
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
    
    // 프레임 번호 체계에 따라 업데이트
    onDisplayOffsetChanged: {
        frameMarkers.requestPaint();
    }
    
    Component.onCompleted: {
        frameMarkers.requestPaint();
    }
}