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
    property var timelineSync: null // TimelineSync 객체 (중앙 동기화 허브)
    
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
    property color backgroundColor: ThemeManager.timelineBackgroundColor
    property color frameColor: ThemeManager.timelineFrameColor
    property color majorFrameColor: ThemeManager.timelineMajorFrameColor
    property color playheadColor: ThemeManager.timelinePlayheadColor
    property color activeTrackColor: ThemeManager.timelineActiveTrackColor
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
    
    // 안정화 기간 관리 개선
    property bool seekStabilizing: false  // 시크 안정화 중 플래그 (새로 추가)
    property int stabilizationPeriod: 300 // 안정화 기간 (ms) - 렉 방지 (새로 추가)
    
    // 플레이헤드 직접 위치 결정 (외부에서 설정된 값이 있으면 우선 사용)
    property real playheadPosition: getExactFramePosition(_internalFrame)
    property bool seekInProgress: false  // 시크 작업 진행 중 플래그
    
    // 프레임 카운터 표시 계산 (설정에 따라 동적 변경)
    property int displayOffset: (mpvObject && mpvObject.oneBasedFrameNumbers) ? 1 : 0
    property string frameCounterText: {
        if (isDragging) {
            // 드래그 중에는 표시 오프셋 적용 - 1-172 또는 0-171
            var displayDragFrame = dragFrame + displayOffset;
            var displayTotalFrames = totalFrames > 0 ? totalFrames : 0;
            
            // 최대 프레임 번호 계산 (0-base면 totalFrames-1, 1-base면 totalFrames)
            var maxDisplayFrame = displayTotalFrames;
            if (displayOffset === 0 && displayTotalFrames > 0) {
                maxDisplayFrame = displayTotalFrames - 1;
            }
            
            return displayDragFrame + " / " + maxDisplayFrame;
        } else {
            // 일반 상태에서도 표시 오프셋 적용
            var displayCurrentFrame = _internalFrame + displayOffset;
            var displayTotalFrames = totalFrames > 0 ? totalFrames : 0;
            
            // 최대 프레임 번호 계산 (0-base면 totalFrames-1, 1-base면 totalFrames)
            var maxDisplayFrame = displayTotalFrames;
            if (displayOffset === 0 && displayTotalFrames > 0) {
                maxDisplayFrame = displayTotalFrames - 1;
            }
            
            return displayCurrentFrame + " / " + maxDisplayFrame;
        }
    }
    
    // TimelineSync 연결 및 동기화
    onTimelineSyncChanged: {
        if (timelineSync) {
            console.log("FrameTimelineBar: TimelineSync connected");
            
            // TimelineSync에서 데이터 동기화
            timelineSync.currentFrameChanged.connect(function(frame) {
                if (!isDragging && currentFrame !== frame) {
                    currentFrame = frame;
                    _internalFrame = frame;
                    updatePlayhead();
                }
            });
            
            timelineSync.totalFramesChanged.connect(function(frames) {
                if (totalFrames !== frames) {
                    totalFrames = frames;
                }
            });
            
            timelineSync.fpsChanged.connect(function(newFps) {
                if (fps !== newFps) {
                    fps = newFps;
                }
            });
            
            timelineSync.playingStateChanged.connect(function(playing) {
                if (isPlaying !== playing) {
                    isPlaying = playing;
                }
            });
        }
    }
    
    // 양방향 바인딩을 위한 핵심 변경사항
    // 외부 프레임이 변경되면 내부 프레임도 업데이트
    onCurrentFrameChanged: {
        if (!isDragging && !seekStabilizing && currentFrame !== _internalFrame) {
            // console.log("Timeline: External frame change detected:", currentFrame);
            
            // 범위 검증 - 외부에서 잘못된 프레임 번호가 전달될 경우 방지
            if (totalFrames > 0 && currentFrame >= totalFrames) {
                console.warn("Timeline: Received invalid frame number:", currentFrame, "max:", totalFrames-1);
                return; // 잘못된 프레임 번호 무시
            }
            
            _internalFrame = currentFrame;
            updatePlayhead();
        }
    }
    
    // 내부 프레임이 변경되면 외부 프레임에 알리고 플레이헤드 위치 업데이트
    on_InternalFrameChanged: {
        // 내부 프레임이 변경되면 플레이헤드 업데이트
        updatePlayhead();
        
        // 범위 검증 - 내부에서 잘못된 프레임 번호가 설정된 경우 방지
        if (totalFrames > 0 && _internalFrame >= totalFrames) {
            console.warn("Timeline: Internal frame out of range:", _internalFrame, "max:", totalFrames-1);
            _internalFrame = totalFrames - 1; // 최대값으로 보정
            return;
        }
        
        // 드래그 중이 아니고, 안정화 중이 아니고, 현재 프레임과 차이가 있을 때만 외부에 알림
        if (!isDragging && !seekStabilizing && _internalFrame !== currentFrame) {
            // TimelineSync를 통한 시크 요청 (우선)
            if (timelineSync) {
                timelineSync.seekToFrame(_internalFrame, true);
            } else {
                // 여기서 바로 currentFrame을 업데이트하지 않고 신호로 보냄
                seekRequested(_internalFrame);
            }
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
    
    // MPV 시크 작업 최적화 - 중복 코드 제거 및 통합 (새로 추가)
    function performMpvSeek(frame) {
        if (!mpvObject) return false;
        
        try {
            console.log("Performing optimized MPV seek to frame:", frame);
            
            // MPV 명령 오류 방지를 위한 핵심 변경: 직접 속성 설정만 사용
            
            // 1. 먼저 안전하게 속성 설정 (MPV 명령보다 더 안정적)
            mpvObject.setProperty("pause", true);
            
            // 2. 프레임 오프셋 조정 (1-based 고정)
            // 항상 1-based로 처리 (중요: 0번 프레임이면 자동으로 1로 변환)
            var adjustedFrame = Math.max(1, frame + 1);
            if (frame === 0) {
                console.log("프레임 인덱스 조정: 0 -> 1 (1-based 인덱싱 적용)");
            }
            
            // 3. 정확한 위치 계산 (조정된 프레임 기준)
            var adjustedPos = (adjustedFrame - 1) / fps; // 0-based 시간 위치 계산
            
            // 4. 명확한 소수점 형식으로 변환 (MPV 명령 오류 방지)
            // toFixed(6)로 명시적 문자열 형식을 만든 후 다시 Number로 변환
            var numericPos = Number(adjustedPos.toFixed(6));
            
            // 5. MPV 명령 대신 직접 속성 설정만 사용 (더 안정적)
            console.log("Setting MPV position directly:", numericPos, "(프레임:", adjustedFrame, ")");
            mpvObject.setProperty("time-pos", numericPos);
            
            // 6. 내부 프레임 업데이트
            _internalFrame = frame;
            currentFrame = frame; // UI와 내부 값 일치시킴
            
            // 7. 강제 업데이트 (UI 반응성)
            mpvObject.update();
            
            // 8. 프레임 동기화 시그널 발생
            seekRequested(frame);
            
            // 9. 동기화 안정화 시작
            seekStabilizing = true;
            
            return true;
        } catch (e) {
            console.error("MPV seek error:", e);
            return false;
        }
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
                    console.log("Timeline: Internal state reset - frame:", mpvFrame);
                }
            } catch (e) {
                console.error("Internal state reset error:", e);
            }
        }
    }
    
    // 강제로 플레이헤드 위치 업데이트 타이머
    Timer {
        id: forceUpdateTimer
        interval: 200  // 200ms 간격 유지
        repeat: true
        // 드래그 중일 때만 타이머 실행 중지 (다른 조건은 제거)
        running: !isDragging
        
        onTriggered: {
            // 현재 프레임 위치에 맞게 플레이헤드 위치 강제 업데이트
            if (!isDragging) {
                // MPV와 현재 프레임 동기화 확인
                if (mpvObject) {
                    try {
                        var timePos = mpvObject.getProperty("time-pos");
                        if (timePos !== undefined && timePos !== null) {
                            var mpvFrame = Math.round(timePos * fps);
                            
                            // MPV와 내부 프레임이 다르면 동기화
                            if (Math.abs(mpvFrame - _internalFrame) > 2) {
                                console.log("Force update: MPV frame=", mpvFrame, "internal frame=", _internalFrame);
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
    
    // 시크 후 검증 타이머 - 더 강력한 동기화 (간격 증가)
    Timer {
        id: verifySeekTimer
        interval: 200  // 간격 더 증가 (200ms) - CPU 부하 추가 감소
        repeat: false
        
        // 시크 실패 방지를 위한 재시도 제한
        property int retryCount: 0
        property int maxRetries: 2
        
        onTriggered: {
            try {
                // 1. 최종 시크 후 실제 위치 다시 확인
                if (mpvObject) {
                    var finalPos = mpvObject.getProperty("time-pos");
                    if (finalPos !== undefined && finalPos !== null) {
                        var finalFrame = Math.round(finalPos * fps);
                        console.log("Verification: MPV frame=", finalFrame, "_internalFrame=", _internalFrame);
                        
                        // 계산된 프레임과 현재 프레임이 크게 다른 경우에만 재동기화
                        // 차이 값 증가 - CPU 부하 감소
                        if (Math.abs(finalFrame - _internalFrame) > 3) {
                            console.log("Frame mismatch detected - synchronizing");
                            
                            // 내부 프레임 업데이트
                            _internalFrame = finalFrame;
                            updatePlayhead();
                            
                            // 차이가 매우 큰 경우에만 다시 시크 시도 (극단적인 경우만)
                            if (Math.abs(finalFrame - currentFrame) > 10 && retryCount < maxRetries) {
                                console.log("Large frame mismatch - retrying seek operation");
                                retryCount++;
                                // 차이가 크면 다시 시크 시도
                                seekRequested(finalFrame);
                                
                                // 타이머 재시작하고 여기서 종료
                                verifySeekTimer.restart();
                                return;
                            }
                        }
                    }
                }
            
                // 2. 시크 완료 처리
                seekInProgress = false;
                retryCount = 0; // 재시도 카운트 리셋
                
                // 3. 안정화 기간 종료 (렉 방지 - 중요한 개선)
                stabilizationTimer.restart();
            } catch (e) {
                console.error("Seek verification error:", e);
                seekInProgress = false;
                retryCount = 0; // 오류 시에도 카운트 리셋
                stabilizationTimer.restart();
            }
        }
    }
    
    // 새로 추가: 안정화 타이머 - 드래그 후 렉 방지를 위한 핵심 개선
    Timer {
        id: stabilizationTimer
        interval: stabilizationPeriod
        repeat: false
        onTriggered: {
            console.log("Stabilization period ended");
            seekStabilizing = false;
            recentlyDragged = false;
        }
    }
    
    // 시크 디바운스 타이머 - MPV 명령 최적화 (간격 증가)
    Timer {
        id: seekDebounceTimer
        interval: 80  // 간격 증가 (80ms) - CPU 부하 감소하되 반응성 유지
        repeat: false
        onTriggered: {
            if (isDragging && mpvObject) {
                try {
                    console.log("Drag seek (debounced), frame:", dragFrame);
                    
                    // 통합된 MPV 시크 함수 사용
                    performMpvSeek(dragFrame);
                    
                    // 시그널 발생 (상위 알림)
                    seekRequested(dragFrame);
                    
                } catch (e) {
                    console.error("Debounce seek error:", e);
                }
            }
        }
    }
    
    // 최종 검증 타이머 추가
    Timer {
        id: finalVerificationTimer
        interval: 100
        repeat: false
        property int verifyDragFrame: 0
        
        onTriggered: {
            try {
                if (mpvObject) {
                    // 실제 위치 확인
                    var actualPos = mpvObject.getProperty("time-pos");
                    var actualFrame = Math.round(actualPos * fps);
                    
                    console.log("Final verification - expected:", verifyDragFrame, "actual:", actualFrame);
                    
                    // 차이가 있으면 마지막으로 한 번 더 시크
                    if (Math.abs(actualFrame - verifyDragFrame) > 0) {
                        var finalPos = verifyDragFrame / fps;
                        
                        // 세 번째 시크 - 더 강제적인 방식
                        mpvObject.command(["seek", finalPos.toFixed(6), "absolute", "exact"]);
                        mpvObject.setProperty("pause", true);
                        
                        // 프레임 설정 강제 업데이트
                        _internalFrame = verifyDragFrame;
                        currentFrame = verifyDragFrame;
                        
                        // 강제 갱신
                        mpvObject.update();
                    }
                }
            } catch (e) {
                console.error("Final verification error:", e);
            } finally {
                // 최종 안정화 타이머 시작
                stabilizationTimer.restart();
                seekInProgress = false;
            }
        }
    }
    
    // Main timeline background
    Rectangle {
        id: timelineBackground
        anchors.fill: parent
        color: backgroundColor
        
        // Create the timeline markers
        Item {
            id: timelineMarkers
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.bottomMargin: 12
            
            // Draw frame markers using a canvas
            Canvas {
                id: frameMarkersCanvas
                anchors.fill: parent
                
                // Redraw on window resize or totalFrames change
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    // Skip if we don't have enough frames
                    if (totalFrames <= 0) return;
                    
                    var h = height;
                    
                    // Draw frame markers
                    ctx.strokeStyle = frameColor;
                    ctx.lineWidth = 1;
                    
                    // Optimize by drawing fewer markers when zoomed out
                    var skipFactor = Math.ceil(totalFrames / width / 0.5);
                    
                    for (var i = 0; i < totalFrames; i += skipFactor) {
                        // Position for current frame
                        var x = i * scaleFactor;
                        
                        // Skip if offscreen
                        if (x > width) break;
                        
                        // Major frame markers (every N frames)
                        if (i % majorFrameInterval === 0) {
                            ctx.beginPath();
                            ctx.moveTo(x, 0);
                            ctx.lineTo(x, h * 0.75);
                            ctx.strokeStyle = majorFrameColor;
                            ctx.stroke();
                            
                            // Add timecode label for major intervals
                            if (i % timecodeInterval === 0) {
                                ctx.fillStyle = timecodeFontColor;
                                ctx.font = timecodeFontSize + "px " + timecodeFontFamily;
                                ctx.textAlign = "center";
                                ctx.fillText(i.toString(), x, h - 2);
                            }
                        } else {
                            // Minor frame markers
                            ctx.beginPath();
                            ctx.moveTo(x, 0);
                            ctx.lineTo(x, h * 0.4);
                            ctx.strokeStyle = frameColor;
                            ctx.stroke();
                        }
                    }
                }
            }
        }
        
        // Active area track (red background for active area)
        Rectangle {
            id: activeTrack
            anchors.left: parent.left
            anchors.right: playhead.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 3
            anchors.bottomMargin: 12
            color: activeTrackColor
        }
        
        // Playhead marker
        Rectangle {
            id: playhead
            width: 1
            anchors.top: parent.top 
            anchors.bottom: parent.bottom
            anchors.topMargin: 3
            anchors.bottomMargin: 12
            x: playheadPosition
            color: playheadColor
            
            // Playhead handle for easier dragging
            Rectangle {
                id: playheadHandle
                width: 3
                height: 8
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                color: playheadColor
                radius: 2
            }
        }
        
        // Mouse area for timeline interaction
        MouseArea {
            id: timelineMouseArea
            anchors.fill: parent
            hoverEnabled: true
            
            onMouseXChanged: {
                // Only update during drag operation
                if (pressed) {
                    var frame = Math.round(mouseX / scaleFactor);
                    
                    // Make sure we have a valid frame in range
                    if (totalFrames > 0) {
                        frame = Math.max(0, Math.min(frame, totalFrames - 1));
                    } else {
                        frame = 0;
                    }
                    
                    // Update drag frame
                    if (dragFrame !== frame) {
                        dragFrame = frame;
                        
                        // Move playhead during drag
                        playhead.x = getExactFramePosition(dragFrame);
                        
                        // Update activeTrack to follow playhead
                        activeTrack.width = playhead.x;
                        
                        // Throttled seeking during drag to improve performance
                        if (throttleSeeking) {
                            // 시크 요청 빈도 제한 - 더 공격적으로 제한 (개선됨)
                            if (lastSentFrame === -1 || Math.abs(dragFrame - lastSentFrame) > 5) {
                                lastSentFrame = dragFrame;
                                seekDebounceTimer.restart();
                            }
                        } else {
                            // Immediate seeking
                            if (mpvObject) {
                                seekDebounceTimer.restart();
                            }
                        }
                    }
                }
            }
            
            onPressed: {
                // 드래그 시작 - 안정화 중단 (새로 추가)
                seekStabilizing = false;
                stabilizationTimer.stop();
                
                isDragging = true;
                recentlyDragged = true;
                
                // MPV 메타데이터 업데이트 차단 설정 (VideoArea에 알림)
                if (mpvObject && mpvObject.parentItem && 
                    typeof mpvObject.parentItem.metadataUpdateBlocked !== "undefined") {
                    mpvObject.parentItem.metadataUpdateBlocked = true;
                    console.log("Timeline: Blocked metadata updates during drag");
                }
                
                // Calculate which frame was clicked
                var frame = Math.round(mouseX / scaleFactor);
                
                // Make sure we have a valid frame in range
                if (totalFrames > 0) {
                    frame = Math.max(0, Math.min(frame, totalFrames - 1));
                } else {
                    frame = 0;
                }
                
                // Update drag frame
                dragFrame = frame;
                lastSentFrame = -1; // Reset
                
                // Move playhead immediately on click
                playhead.x = getExactFramePosition(dragFrame);
                
                // Update activeTrack to follow playhead
                activeTrack.width = playhead.x;
                
                // Immediately seek to the clicked position
                if (mpvObject) {
                    seekInProgress = true;
                    try {
                        // 클릭 시크 개선 - 더 강력한 시크 방식 적용
                        // 1. 내부 프레임 즉시 업데이트
                        _internalFrame = dragFrame;
                        currentFrame = dragFrame;
                        
                        // 2. 통합된 MPV 시크 함수 사용 (개선)
                        performMpvSeek(dragFrame);
                        
                        // 3. 시그널 강화 - 여러 경로로 시그널 발생
                        console.log("Click seek:", dragFrame);
                        
                        // 4. VideoArea 컴포넌트의 seekToFrame 함수 직접 호출 시도
                        if (mpvObject && mpvObject.parentItem && 
                            typeof mpvObject.parentItem.seekToFrame === "function") {
                            mpvObject.parentItem.seekToFrame(dragFrame);
                        }
                        
                        // 5. 중요: 클릭 시크를 위한 강화된 검증 즉시 시작
                        Qt.callLater(function() {
                            verifySeekTimer.restart();
                        });
                    } catch (e) {
                        console.error("Click seek error:", e);
                        seekInProgress = false;
                    }
                }
            }
            
            onReleased: {
                // If dragging was actually happening
                if (isDragging) {
                    console.log("Timeline drag released, final frame:", dragFrame);
                    
                    // Update internal frame to match drag frame
                    _internalFrame = dragFrame;
                    
                    // 안정화 기간 시작 (새로 추가 - 중요한 개선)
                    seekStabilizing = true;
                    
                    // 메타데이터 업데이터는 드래그 후에도 계속 차단 유지
                    // 메타데이터는 처음 파일 로드시에만 필요하므로 해제하지 않음
                    
                    // Ensure a final accurate seek occurs
                    if (mpvObject) {
                        try {
                            // 드래그 후 프레임 멈춤 문제 해결을 위한 개선된 시크 처리
                            
                            // 1. 드래그 후 첫 번째 시크 - 속성 직접 설정 (빠른 응답)
                            var pos = dragFrame / fps;
                            mpvObject.setProperty("time-pos", pos);
                            mpvObject.setProperty("pause", true);
                            
                            // 2. 지연 시간을 둔 후 두 번째 시크 실행 (더 정확한 프레임 설정)
                            Qt.callLater(function() {
                                try {
                                    // 정확한 시크 명령 실행
                                    mpvObject.command(["seek", pos.toFixed(6), "absolute", "exact"]);
                                    
                                    // 강제 업데이트 요청
                                    mpvObject.update();
                                    
                                    // 상태 확인 타이머 재시작
                                    verifySeekTimer.restart();
                                } catch (e) {
                                    console.error("Second seek error:", e);
                                }
                            });
                            
                            // 3. 더 긴 지연 후 최종 프레임 위치 확인 및 수정
                            Qt.callLater(function() {
                                // 새로 추가한 최종 검증 타이머 사용
                                finalVerificationTimer.verifyDragFrame = dragFrame;
                                finalVerificationTimer.restart();
                            });
                            
                        } catch (e) {
                            console.error("Final seek error:", e);
                            // 오류 시에도 안정화 타이머 시작
                            stabilizationTimer.restart();
                            seekInProgress = false;
                        }
                    } else {
                        // MPV가 없어도 안정화 타이머 시작
                        stabilizationTimer.restart();
                        seekInProgress = false;
                    }
                    
                    // End drag operation
                    isDragging = false;
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
    
    // Update display when properties change
    onTotalFramesChanged: {
        frameMarkersCanvas.requestPaint();
    }
    
    onWidthChanged: {
        frameMarkersCanvas.requestPaint();
    }
    
    onFpsChanged: {
        timecodeInterval = Math.max(10, Math.floor(fps));
        frameMarkersCanvas.requestPaint();
    }
    
    // 프레임 번호 체계에 따라 업데이트
    onDisplayOffsetChanged: {
        frameMarkersCanvas.requestPaint();
    }
    
    Component.onCompleted: {
        frameMarkersCanvas.requestPaint();
    }
}