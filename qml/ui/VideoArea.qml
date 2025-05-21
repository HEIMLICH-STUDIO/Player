import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

// Conditional import - check MPV and TimelineSync support
// Requires hasMpvSupport context property to be set from C++ first
import "../utils"

// Area containing the MPV video player
Item {
    id: root
    
    // Video related properties
    property int frame: 0
    property int frames: 0
    property string filename: ""
    property real fps: 24.0
    property bool isPlaying: false
    signal onIsPlayingChangedEvent(bool playing)
    
    // Signals (Note: renamed to avoid duplicates)    
    signal onFrameChangedEvent(int frame)
    signal onTotalFramesChangedEvent(int frames)
    signal onFileChangedEvent(string filename)
    signal onFpsChangedEvent(real fps)
    
    // MPV support flag (set from C++ rootContext)
    property bool mpvSupported: typeof hasMpvSupport !== "undefined" ? hasMpvSupport : false
    
    // Dark theme background
    Rectangle {
        anchors.fill: parent
        color: ThemeManager.backgroundColor
        z: -1 // Position behind MPV player
    }
    
    // Message overlay (for errors, etc.)
    Rectangle {
        anchors.centerIn: parent
        width: messageText.width + 40
        height: messageText.height + 20
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 8
        visible: messageText.text !== ""
        
        Text {
            id: messageText
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: ThemeManager.normalFontSize
            font.family: ThemeManager.defaultFont
            text: ""
        }
        
        // Automatically hide message
        Timer {
            id: messageTimer
            interval: 3000
            running: messageText.text !== ""
            onTriggered: messageText.text = ""
        }
    }
    
    // Placeholder when MPV support is unavailable
    Rectangle {
        id: placeholderRect
        anchors.fill: parent
        color: ThemeManager.backgroundColor
        visible: !mpvSupported
        
        Column {
            anchors.centerIn: parent
            spacing: 10
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MPV support not available"
                color: ThemeManager.textColor
                font.pixelSize: ThemeManager.largeFontSize
                font.family: ThemeManager.defaultFont
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Add HAVE_MPV definition during build"
                color: ThemeManager.secondaryTextColor
                font.pixelSize: ThemeManager.normalFontSize
                font.family: ThemeManager.defaultFont
            }
            
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Open File (Placeholder)"
                onClicked: showMessage("MPV support required to play videos")
            }
        }
    }
    
    // File dialog
    FileDialog {
        id: fileDialog
        title: "Open Video File"
        nameFilters: ["Video files (*.mp4 *.mkv *.avi *.mov *.wmv *.flv)"]
        onAccepted: {
            if (mpvSupported) {
                loadFile(selectedFile)
            } else {
                showMessage("Cannot play video: MPV support not available")
            }
        }
    }
    
    // MPV component loaded dynamically when supported
    Loader {
        id: mpvLoader
        anchors.fill: parent
        active: mpvSupported
        sourceComponent: mpvSupported ? mpvComponent : null
    }
    
    // MPV component definition - conditionally loaded
    Component {
        id: mpvComponent
        
        Item {
            // MPV and TimelineSync are only used when importable
            property var mpvPlayer: null
            property var timelineSync: null
            
            Component.onCompleted: {
                // Attempt to create components dynamically
                try {
                    // Try to create MPV component dynamically
                    var component = Qt.createQmlObject(
                        'import mpv 1.0; MpvObject { anchors.fill: parent }',
                        this,
                        "dynamically_created_mpv"
                    );
                    
                    if (component) {
                        mpvPlayer = component;
                        console.log("MPV component created successfully");
                        
                        // Connect events
                        connectMpvEvents();
                    }
                    
                    // Try to create TimelineSync dynamically
                    var syncComponent = Qt.createQmlObject(
                        'import app.sync 1.0; TimelineSync {}',
                        this,
                        "dynamically_created_sync"
                    );
                    
                    if (syncComponent) {
                        timelineSync = syncComponent;
                        console.log("TimelineSync component created successfully");
                    }
                } catch (e) {
                    console.error("Failed to create MPV components:", e);
                    root.showMessage("Error: " + e);
                }
            }
            
            // Function to connect MPV events
            function connectMpvEvents() {
                if (!mpvPlayer) return;
                
                mpvPlayer.positionChanged.connect(function(position) {
                    // Update current frame
                    if (position >= 0 && root.fps > 0) {
                        var frame = Math.round(position * root.fps);
                        root.frame = frame;
                        root.onFrameChangedEvent(frame);
                    }
                });
                
                mpvPlayer.durationChanged.connect(function(duration) {
                    // Update total frame count
                    if (duration > 0 && root.fps > 0) {
                        var totalFrames = Math.ceil(duration * root.fps);
                        root.frames = totalFrames;
                        root.onTotalFramesChangedEvent(totalFrames);
                    }
                });
                
                mpvPlayer.filenameChanged.connect(function(filename) {
                    root.filename = filename;
                    root.onFileChangedEvent(filename);
                });
                
                mpvPlayer.fpsChanged.connect(function(fps) {
                    if (fps > 0) {
                        root.fps = fps;
                        root.onFpsChangedEvent(fps);
                        
                        // When FPS changes, update total frame count as well
                        if (mpvPlayer.duration > 0) {
                            var totalFrames = Math.ceil(mpvPlayer.duration * root.fps);
                            root.frames = totalFrames;
                            root.onTotalFramesChangedEvent(totalFrames);
                        }
                    }
                });
                
                if (mpvPlayer.hasOwnProperty('pauseChanged')) {
                    mpvPlayer.pauseChanged.connect(function(paused) {
                        root.isPlaying = !paused;
                        root.onIsPlayingChangedEvent(!paused);
                    });
                }
            }
        }
    }
    
    // Show message
    function showMessage(text) {
        messageText.text = text;
        messageTimer.restart();
    }
    
    // Open file dialog
    function openFile() {
        if (mpvSupported) {
            fileDialog.open()
        } else {
            showMessage("MPV support not available")
        }
    }
    
    // Load file
    function loadFile(path) {
        if (!mpvSupported) {
            showMessage("Cannot load file: MPV support not available");
            return;
        }
        
        try {
            var mpvPlayer = getMpvPlayer();
            if (mpvPlayer) {
                mpvPlayer.command(["loadfile", path]);
                showMessage("Loading: " + path);
            } else {
                showMessage("MPV player not initialized");
            }
        } catch (e) {
            console.error("Failed to load file:", e);
            showMessage("Error loading file: " + e);
        }
    }
    
    // 안전하게 MPV 플레이어 객체 가져오기
    function getMpvPlayer() {
        try {
            if (!mpvSupported || !mpvLoader || !mpvLoader.item) {
                return null;
            }
            return mpvLoader.item.mpvPlayer;
        } catch (e) {
            console.error("Error getting MPV player:", e);
            return null;
        }
    }
    
    // 재생/일시정지 토글
    function playPause() {
        var player = getMpvPlayer();
        if (player) {
            try {
                player.playPause();
                isPlaying = !player.pause;
                onIsPlayingChangedEvent(isPlaying);
            } catch (e) {
                console.error("Error toggling play/pause:", e);
                showMessage("Error toggling play/pause: " + e);
            }
        } else {
            showMessage("Player not initialized");
        }
    }
    
    // 프레임 앞으로 이동
    function stepForward(frames) {
        if (!frames || frames < 1) frames = 1; // 기본값 설정
        
        var player = getMpvPlayer();
        if (player) {
            try {
                // 1. 먼저 일시정지 상태로 변경
                if (!player.pause) {
                    player.pause = true;
                }
                
                // 2. 현재 위치 확인
                var currentPos = player.getProperty("time-pos");
                // QML에서 숫자인지 확인
                if (currentPos === undefined || currentPos === null || isNaN(currentPos)) {
                    showMessage("Cannot determine current position");
                    return;
                }
                
                // 3. 총 프레임 수 확인
                var duration = player.getProperty("duration");
                if (duration === undefined || duration === null || isNaN(duration)) {
                    showMessage("Cannot determine video duration");
                    return;
                }
                var totalFrames = Math.floor(duration * fps);
                
                // 4. 현재 프레임 계산
                var currentFrame = Math.round(currentPos * fps);
                
                // 5. 목표 프레임 계산 (최대 totalFrames-1)
                var targetFrame = Math.min(totalFrames - 1, currentFrame + frames);
                
                // 6. 목표 프레임을 시간으로 변환
                var targetPos = targetFrame / fps;
                
                // 7. 시크 명령 실행
                console.log("Seeking forward from frame " + currentFrame + " to " + targetFrame);
                player.command(["seek", targetPos.toString(), "absolute", "exact"]);
                
                // 8. 현재 프레임 업데이트
                player.setProperty("pause", true); // 일시정지 상태 유지
                frame = targetFrame;
                onFrameChangedEvent(targetFrame);
            } catch (e) {
                console.error("Error stepping forward:", e);
                showMessage("Error stepping forward: " + e);
            }
        } else {
            showMessage("Player not initialized");
        }
    }
    
    // 프레임 뒤로 이동
    function stepBackward(frames) {
        if (!frames || frames < 1) frames = 1; // 기본값 설정
        
        var player = getMpvPlayer();
        if (player) {
            try {
                // 1. 먼저 일시정지 상태로 변경
                if (!player.pause) {
                    player.pause = true;
                }
                
                // 2. 현재 위치 확인
                var currentPos = player.getProperty("time-pos");
                // QML에서 숫자인지 확인
                if (currentPos === undefined || currentPos === null || isNaN(currentPos)) {
                    showMessage("Cannot determine current position");
                    return;
                }
                
                // 3. 현재 프레임 계산
                var currentFrame = Math.round(currentPos * fps);
                
                // 4. 목표 프레임 계산 (최소 0)
                var targetFrame = Math.max(0, currentFrame - frames);
                
                // 5. 목표 프레임을 시간으로 변환
                var targetPos = targetFrame / fps;
                
                // 6. 시크 명령 실행
                console.log("Seeking backward from frame " + currentFrame + " to " + targetFrame);
                player.command(["seek", targetPos.toString(), "absolute", "exact"]);
                
                // 7. 현재 프레임 업데이트
                player.setProperty("pause", true); // 일시정지 상태 유지
                frame = targetFrame;
                onFrameChangedEvent(targetFrame);
            } catch (e) {
                console.error("Error stepping backward:", e);
                showMessage("Error stepping backward: " + e);
            }
        } else {
            showMessage("Player not initialized");
        }
    }
    
    // 특정 프레임으로 이동 - 강화된 구현
    function seekToFrame(targetFrame) {
        var player = getMpvPlayer();
        if (player) {
            try {
                console.log("VideoArea: 프레임 시크 요청 -", targetFrame);
                
                // 1. 영상 위치 검증
                if (typeof player.duration !== 'undefined' && player.duration <= 0) {
                    console.error("유효한 영상이 없음 - 시크 불가");
                    return;
                }
                
                // 2. 프레임 범위 확인
                if (targetFrame < 0 || targetFrame >= frames) {
                    console.error("유효하지 않은 프레임 범위:", targetFrame, "범위:", 0, "-", frames-1);
                    targetFrame = Math.max(0, Math.min(targetFrame, frames - 1));
                }
                
                // 3. 타임스탬프 계산
                var timePos = targetFrame / fps;
                
                // 시크 명령 카운트 - 디버깅용
                console.log("시크 시작 - 프레임:", targetFrame, "시간:", timePos);
                
                // 4. MPV 강력한 시크 구현 - 모든 메서드 시도
                // 4.1. 직접 속성 설정 (즉각 반응)
                player.setProperty("time-pos", timePos);
                
                // 4.2. 명령 인터페이스 사용 (정확도)
                player.command(["seek", timePos.toString(), "absolute", "exact"]);
                
                // 4.3 사용 가능한 경우 내장 API 활용
                if (typeof player.seekToPosition === "function") {
                    player.seekToPosition(timePos);
                }
                
                // 5. 일시정지 상태 확인
                if (!isPlaying) {
                    player.setProperty("pause", true);
                }
                
                // 6. 내부 프레임 즉시 업데이트 (UI 응답성)
                frame = targetFrame;
                onFrameChangedEvent(targetFrame);
                
                // 7. 시크 검증 및 강화 - 시크가 완전히 적용되도록 함
                secondSeekTimer.timePos = timePos;
                secondSeekTimer.targetFrame = targetFrame;
                secondSeekTimer.start();
                
                // 8. 최종 검증
                finalVerifyTimer.timePos = timePos;
                finalVerifyTimer.targetFrame = targetFrame;
                finalVerifyTimer.start();
                
                // 9. 시크 결과 확인 - 디버그 목적
                Qt.callLater(function() {
                    try {
                        var actualPos = player.getProperty("time-pos");
                        var actualFrame = Math.round(actualPos * fps);
                        console.log("시크 즉시 확인: 요청=", targetFrame, "실제=", actualFrame);
                    } catch (e) {
                        console.error("시크 결과 확인 오류:", e);
                    }
                });
                
                return true;
            } catch (e) {
                console.error("프레임 시크 오류:", e);
                showMessage("프레임 시크 오류: " + e);
                return false;
            }
        } else {
            console.error("시크 불가: 플레이어 초기화 안됨");
            showMessage("Player not initialized");
            return false;
        }
    }
    
    // 두 번째 시크 타이머 (setTimeout 대체)
    Timer {
        id: secondSeekTimer
        interval: 100
        repeat: false
        property real timePos: 0
        property int targetFrame: 0
        
        onTriggered: {
            var player = getMpvPlayer();
            if (player) {
                try {
                    // 1. 명령어로 한 번 더 정확한 위치 지정
                    player.command(["seek", timePos.toString(), "absolute", "exact"]);
                    
                    // 2. 일시정지 상태 유지 (일시정지 모드일 때)
                    if (!isPlaying) {
                        player.setProperty("pause", true);
                    }
                    
                    // 3. 현재 프레임 상태 재확인 및 시그널 발생
                    var actualPos = player.getProperty("time-pos");
                    if (actualPos !== undefined && actualPos !== null) {
                        var actualFrame = Math.round(actualPos * fps);
                        if (Math.abs(actualFrame - targetFrame) > 1) {
                            console.log("시크 검증: 프레임 불일치 - 현재:", actualFrame, "요청:", targetFrame);
                            
                            // 다시 시크 시도
                            player.setProperty("time-pos", timePos);
                            
                            // UI 업데이트
                            frame = actualFrame;
                            onFrameChangedEvent(actualFrame);
                        }
                    }
                } catch (e) {
                    console.error("Second seek timer error:", e);
                }
            }
        }
    }
    
    // 최종 검증 타이머 (완전한 동기화 보장)
    Timer {
        id: finalVerifyTimer
        interval: 250
        repeat: false
        property real timePos: 0
        property int targetFrame: 0
        
        onTriggered: {
            var player = getMpvPlayer();
            if (player) {
                try {
                    // 최종 상태 검증
                    var actualPos = player.getProperty("time-pos");
                    if (actualPos !== undefined && actualPos !== null) {
                        var actualFrame = Math.round(actualPos * fps);
                        
                        // 여전히 불일치가 있는지 확인
                        if (Math.abs(actualFrame - targetFrame) > 1) {
                            console.log("최종 검증: 프레임 불일치 감지 - 현재:", actualFrame, "목표:", targetFrame);
                            
                            // 일시정지 확인 - 일시정지 상태에서만 정확한 프레임 맞추기
                            if (!isPlaying) {
                                player.setProperty("pause", true);
                                
                                // 마지막 시도 - 3중 시크 명령 송출
                                // 1. 속성 직접 설정
                                player.setProperty("time-pos", timePos);
                                
                                // 2. 명령 인터페이스 사용
                                player.command(["seek", timePos.toString(), "absolute", "exact"]);
                                
                                // 3. 최우선 위치로 시크 (없으면 무시)
                                if (typeof player.seekToPosition === "function") {
                                    player.seekToPosition(timePos);
                                }
                                
                                // 4. 1회 추가 검증
                                Qt.callLater(function() {
                                    try {
                                        var finalPos = player.getProperty("time-pos");
                                        var finalFrame = Math.round(finalPos * fps);
                                        console.log("최종 검증 결과: 목표=", targetFrame, "최종=", finalFrame);
                                        
                                        // UI 업데이트
                                        frame = finalFrame;
                                        onFrameChangedEvent(finalFrame);
                                    } catch (e) {
                                        console.error("최종 확인 오류:", e);
                                    }
                                });
                            }
                        } else {
                            console.log("프레임 시크 최종 확인 완료:", targetFrame);
                        }
                    }
                } catch (e) {
                    console.error("최종 검증 타이머 오류:", e);
                }
            }
        }
    }
    
    // Toggle scopes
    function toggleScopes() {
        if (!mpvSupported) {
            showMessage("Cannot toggle scopes: MPV support not available");
            return;
        }
        
        // This is a placeholder - actual implementation depends on ScopeWindow
        showMessage("Scopes toggled");
    }
    
    // Add video filter
    function addVideoFilter(filter) {
        if (!mpvSupported) {
            showMessage("Cannot add filter: MPV support not available");
            return false;
        }
        
        var mpvPlayer = mpvLoader.item ? mpvLoader.item.mpvPlayer : null;
        if (mpvPlayer) {
            try {
                console.log("Adding video filter:", filter);
                mpvPlayer.command(["vf", "add", filter]);
                return true;
            } catch (e) {
                console.error("Failed to add filter:", e);
                showMessage("Filter error: " + e);
                return false;
            }
        }
        
        showMessage("MPV player not initialized");
        return false;
    }
    
    // Remove video filter
    function removeVideoFilter(filter) {
        if (!mpvSupported) {
            showMessage("Cannot remove filter: MPV support not available");
            return false;
        }
        
        var mpvPlayer = mpvLoader.item ? mpvLoader.item.mpvPlayer : null;
        if (mpvPlayer) {
            try {
                console.log("Removing video filter:", filter);
                mpvPlayer.command(["vf", "remove", filter]);
                return true;
            } catch (e) {
                console.error("Failed to remove filter:", e);
                showMessage("Filter error: " + e);
                return false;
            }
        }
        
        showMessage("MPV player not initialized");
        return false;
    }
    
    // Keyboard focus
    focus: true
    Keys.onSpacePressed: playPause()
    Keys.onLeftPressed: stepBackward(1)
    Keys.onRightPressed: stepForward(1)
}
