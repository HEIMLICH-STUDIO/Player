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
    
    // 중요: mpvLoader와 mpvPlayer를 직접 노출
    property alias mpvLoader: mpvLoader
    property var mpvPlayer: mpvLoader.item ? mpvLoader.item.mpvPlayer : null
    
    // Hover toolbar properties
    property bool showToolbar: false
    
    signal onIsPlayingChangedEvent(bool playing)
    
    // Signals (Note: renamed to avoid duplicates)    
    signal onFrameChangedEvent(int frame)
    signal onTotalFramesChangedEvent(int frames)
    signal onFileChangedEvent(string filename)
    signal onFpsChangedEvent(real fps)
    signal onMetadataChanged()
    
    // Video metadata properties
    property string videoCodec: ""
    property string videoFormat: ""
    property string videoResolution: ""
    property string videoBitrate: ""
    property real videoAspectRatio: 1.0
    property string videoColorSpace: ""
    property string audioCodec: ""
    property string audioChannels: ""
    property string audioSampleRate: ""
    property string creationDate: ""
    
    // MPV support flag (set from C++ rootContext)
    property bool mpvSupported: typeof hasMpvSupport !== "undefined" ? hasMpvSupport : false
    
    // 메타데이터가 이미 로드되었는지 추적하는 플래그
    property bool metadataLoaded: false
    
    // 시크/드래그 중 메타데이터 업데이트 방지 플래그
    property bool metadataUpdateBlocked: false
    
    // MPV 객체 초기화 시 이벤트 연결
    Component.onCompleted: {
        console.log("VideoArea initialized, waiting for MPV connection");
    }
    
    // MPV 플레이어 변경 감지 및 이벤트 연결
    onMpvPlayerChanged: {
        if (mpvPlayer) {
            console.log("VideoArea: mpvPlayer changed, attempting to connect events");
            
            // fileLoaded 시그널 직접 연결
            try {
                if (typeof mpvPlayer.fileLoaded === "function" ||
                    mpvPlayer.hasOwnProperty('fileLoaded')) {
                    mpvPlayer.fileLoaded.connect(function() {
                        console.log("VideoArea: File load completed event received");
                        metadataLoaded = false;
                        
                        // 시크/드래그 중이 아닐 때만 메타데이터 업데이트
                        if (!metadataUpdateBlocked) {
                            fetchVideoMetadata();
                            console.log("VideoArea: Metadata fetch called");
                        } else {
                            console.log("VideoArea: Metadata update blocked (during seek/drag)");
                            // 지연된 메타데이터 가져오기 예약
                            delayedMetadataTimer.restart();
                        }
                    });
                    console.log("VideoArea: fileLoaded signal connection successful");
                } else {
                    console.warn("VideoArea: fileLoaded signal not found, using alternative method");
                    
                    // 대체 방법: 파일명 변경 감지
                    if (mpvPlayer.hasOwnProperty('filenameChanged')) {
                        mpvPlayer.filenameChanged.connect(function() {
                            console.log("VideoArea: Filename change detected, resetting metadata");
                            metadataLoaded = false;
                            
                            // 시크/드래그 중이 아닐 때만 즉시 메타데이터 업데이트
                            if (!metadataUpdateBlocked) {
                                // 약간의 지연 후 메타데이터 가져오기
                                metadataFetchTimer.restart();
                            } else {
                                // 시크/드래그 중이면 더 긴 지연 후 업데이트
                                delayedMetadataTimer.restart();
                            }
                        });
                        console.log("VideoArea: filenameChanged signal connected as alternative");
                    }
                }
            } catch (e) {
                console.error("VideoArea: Event connection error:", e);
            }
        }
    }
    
    // Dark theme background
    Rectangle {
        anchors.fill: parent
        color: ThemeManager.backgroundColor
        z: -1 // Position behind MPV player
    }
    
    // Hover toolbar at the top
    Rectangle {
        id: topToolbar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 30  // Smaller height
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: root.showToolbar
        z: 100 // Above the video
        
        // Animate toolbar appearance - faster animation
        opacity: root.showToolbar ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 100 }  // Faster animation
        }
        
        // Video title
        Text {
            id: videoTitleText
            anchors.centerIn: parent
            width: parent.width * 0.8
            color: "white"
            font.pixelSize: ThemeManager.smallFontSize  // Smaller font
            font.family: ThemeManager.monoFont  // Mono font
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            text: {
                // Extract just the filename without path
                var path = root.filename;
                if (path) {
                    var lastSlash = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
                    return lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
                }
                return "No file loaded";
            }
        }
    }
    
    // Mouse area to detect hover
    MouseArea {
        id: videoHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // Don't capture clicks, just hover
        
        onEntered: {
            // Only show if mouse is in the top portion
            if (mouseY < topToolbar.height * 2) {
                root.showToolbar = true;
            }
        }
        
        onExited: {
            root.showToolbar = false;
        }
        
        onPositionChanged: {
            // Only show if mouse is in the top portion
            if (mouseY < topToolbar.height * 2) {
                root.showToolbar = true;
                toolbarHideTimer.stop();
            } else {
                root.showToolbar = false;
            }
        }
    }
    
    // Timer to hide toolbar after inactivity - shorter time
    Timer {
        id: toolbarHideTimer
        interval: 1000 // 1 second
        onTriggered: root.showToolbar = false
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
                        
                        // 진행 표시줄(OSD) 비활성화
                        mpvPlayer.setProperty("osd-level", 0);        // OSD 레벨 완전 비활성화
                        mpvPlayer.setProperty("osd-bar", "no");       // 타임라인 바 비활성화
                        mpvPlayer.setProperty("osd-on-seek", "no");   // 시크 시 OSD 표시 안함
                        
                        // Connect events
                        connectMpvEvents();
                        
                        // Setup file loaded callback handler
                        if (mpvPlayer) {
                            mpvPlayer.fileLoaded.connect(function() {
                                console.log("File loaded event triggered");
                                // Wait a moment to ensure all properties are available
                                Qt.callLater(function() {
                                    fetchVideoMetadata();
                                });
                            });
                        }
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
                    console.error("Failed to create components:", e);
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
                    console.log("VideoArea: Filename change detected -", filename);
                    
                    // 이전 파일과 다른 경우에만 처리
                    if (root.filename !== filename) {
                        root.filename = filename;
                        root.onFileChangedEvent(filename);
                        
                        // 파일이 변경되면 메타데이터 로드 상태 강제 초기화
                        metadataLoaded = false;
                        console.log("VideoArea: New file detected, resetting metadata load state");
                        
                        // 즉시 메타데이터 가져오기 시도
                        fetchVideoMetadata();
                        
                        // 백업으로 타이머도 시작
                        metadataFetchTimer.restart();
                    }
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
                
                // Connect to file-loaded event if available
                if (mpvPlayer.hasOwnProperty('fileLoaded')) {
                    mpvPlayer.fileLoaded.connect(function() {
                        console.log("File fully loaded, fetching metadata");
                        metadataLoaded = false; // 확실히 초기화
                        // 즉시 메타데이터 가져오기 시도
                        fetchVideoMetadata();
                        
                        // 첫 번째 시도가 실패할 경우를 대비한 두 번째 시도 예약
                        Qt.callLater(function() {
                            if (!metadataLoaded) {
                                console.log("First metadata load failed, trying again");
                                fetchVideoMetadata();
                            }
                        });
                    });
                }
                
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
            if (mpvPlayer) {
                mpvPlayer.command(["loadfile", path]);
                showMessage("Loading: " + path);
                
                // Set up a timer to fetch metadata after loading
                metadataFetchTimer.start();
            } else {
                showMessage("MPV player not initialized");
            }
        } catch (e) {
            console.error("Failed to load file:", e);
            showMessage("Error loading file: " + e);
        }
    }
    
    // 재생/일시정지 토글
    function playPause() {
        if (mpvPlayer) {
            try {
                mpvPlayer.playPause();
                isPlaying = !mpvPlayer.pause;
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
        
        if (mpvPlayer) {
            try {
                // 1. 먼저 일시정지 상태로 변경
                if (!mpvPlayer.pause) {
                    mpvPlayer.pause = true;
                }
                
                // 2. 현재 위치 확인
                var currentPos = mpvPlayer.getProperty("time-pos");
                // QML에서 숫자인지 확인
                if (currentPos === undefined || currentPos === null || isNaN(currentPos)) {
                    showMessage("Cannot determine current position");
                    return;
                }
                
                // 3. 총 프레임 수 확인
                var duration = mpvPlayer.getProperty("duration");
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
                mpvPlayer.command(["seek", targetPos.toString(), "absolute", "exact"]);
                
                // 8. 현재 프레임 업데이트
                mpvPlayer.setProperty("pause", true); // 일시정지 상태 유지
                root.frame = targetFrame;
                root.onFrameChangedEvent(targetFrame);
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
        
        if (mpvPlayer) {
            try {
                // 1. 먼저 일시정지 상태로 변경
                if (!mpvPlayer.pause) {
                    mpvPlayer.pause = true;
                }
                
                // 2. 현재 위치 확인
                var currentPos = mpvPlayer.getProperty("time-pos");
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
                mpvPlayer.command(["seek", targetPos.toString(), "absolute", "exact"]);
                
                // 7. 현재 프레임 업데이트
                mpvPlayer.setProperty("pause", true); // 일시정지 상태 유지
                root.frame = targetFrame;
                root.onFrameChangedEvent(targetFrame);
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
        if (mpvPlayer) {
            try {
                console.log("VideoArea: Frame seek request -", targetFrame);
                
                // 메타데이터 업데이트 차단 설정
                metadataUpdateBlocked = true;
                
                // 1. 영상 위치 검증
                if (typeof mpvPlayer.duration !== 'undefined' && mpvPlayer.duration <= 0) {
                    console.error("No valid video - cannot seek");
                    metadataUpdateBlocked = false; // 차단 해제
                    return;
                }
                
                // 2. 프레임 범위 확인
                if (targetFrame < 0 || targetFrame >= frames) {
                    console.error("Invalid frame range:", targetFrame, "range:", 0, "-", frames-1);
                    targetFrame = Math.max(0, Math.min(targetFrame, frames - 1));
                }
                
                // 3. 타임스탬프 계산
                var timePos = targetFrame / fps;
                
                // 시크 명령 카운트 - 디버깅용
                console.log("Seek started - frame:", targetFrame, "time:", timePos);
                
                // 4. MPV 강력한 시크 구현 - 모든 메서드 시도
                // 4.1. 직접 속성 설정 (즉각 반응)
                mpvPlayer.setProperty("time-pos", timePos);
                
                // 4.2. 명령 인터페이스 사용 (정확도)
                mpvPlayer.command(["seek", timePos.toString(), "absolute", "exact"]);
                
                // 4.3 사용 가능한 경우 내장 API 활용
                if (typeof mpvPlayer.seekToPosition === "function") {
                    mpvPlayer.seekToPosition(timePos);
                }
                
                // 5. 일시정지 상태 확인
                if (!isPlaying) {
                    mpvPlayer.setProperty("pause", true);
                }
                
                // 6. 내부 프레임 즉시 업데이트 (UI 응답성)
                root.frame = targetFrame;
                root.onFrameChangedEvent(targetFrame);
                
                // 7. 시크 검증 및 강화 - 시크가 완전히 적용되도록 함
                secondSeekTimer.timePos = timePos;
                secondSeekTimer.targetFrame = targetFrame;
                secondSeekTimer.start();
                
                // 8. 최종 검증
                finalVerifyTimer.timePos = timePos;
                finalVerifyTimer.targetFrame = targetFrame;
                finalVerifyTimer.start();
                
                // 9. 메타데이터 업데이트 차단 해제 예약
                metadataBlockReleaseTimer.restart();
                
                // 10. 시크 결과 확인 - 디버그 목적
                Qt.callLater(function() {
                    try {
                        var actualPos = mpvPlayer.getProperty("time-pos");
                        var actualFrame = Math.round(actualPos * fps);
                        console.log("Immediate seek verification: requested=", targetFrame, "actual=", actualFrame);
                    } catch (e) {
                        console.error("Seek result verification error:", e);
                    }
                });
                
                return true;
            } catch (e) {
                console.error("Frame seek error:", e);
                showMessage("Frame seek error: " + e);
                metadataUpdateBlocked = false; // 차단 해제
                return false;
            }
        } else {
            console.error("Cannot seek: player not initialized");
            showMessage("Player not initialized");
            metadataUpdateBlocked = false; // 차단 해제
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
            if (mpvPlayer) {
                try {
                    // 1. 명령어로 한 번 더 정확한 위치 지정
                    mpvPlayer.command(["seek", timePos.toString(), "absolute", "exact"]);
                    
                    // 2. 일시정지 상태 유지 (일시정지 모드일 때)
                    if (!isPlaying) {
                        mpvPlayer.setProperty("pause", true);
                    }
                    
                    // 3. 현재 프레임 상태 재확인 및 시그널 발생
                    var actualPos = mpvPlayer.getProperty("time-pos");
                    if (actualPos !== undefined && actualPos !== null) {
                        var actualFrame = Math.round(actualPos * fps);
                        if (Math.abs(actualFrame - targetFrame) > 1) {
                            console.log("Seek verification: Frame mismatch - current:", actualFrame, "requested:", targetFrame);
                            
                            // 다시 시크 시도
                            mpvPlayer.setProperty("time-pos", timePos);
                            
                            // UI 업데이트
                            root.frame = actualFrame;
                            root.onFrameChangedEvent(actualFrame);
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
            if (mpvPlayer) {
                try {
                    // 최종 상태 검증
                    var actualPos = mpvPlayer.getProperty("time-pos");
                    if (actualPos !== undefined && actualPos !== null) {
                        var actualFrame = Math.round(actualPos * fps);
                        
                        // 여전히 불일치가 있는지 확인
                        if (Math.abs(actualFrame - targetFrame) > 1) {
                            console.log("Final verification: Frame mismatch detected - current:", actualFrame, "target:", targetFrame);
                            
                            // 일시정지 확인 - 일시정지 상태에서만 정확한 프레임 맞추기
                            if (!isPlaying) {
                                mpvPlayer.setProperty("pause", true);
                                
                                // 마지막 시도 - 3중 시크 명령 송출
                                // 1. 속성 직접 설정
                                mpvPlayer.setProperty("time-pos", timePos);
                                
                                // 2. 명령 인터페이스 사용
                                mpvPlayer.command(["seek", timePos.toString(), "absolute", "exact"]);
                                
                                // 3. 최우선 위치로 시크 (없으면 무시)
                                if (typeof mpvPlayer.seekToPosition === "function") {
                                    mpvPlayer.seekToPosition(timePos);
                                }
                                
                                // 4. 1회 추가 검증
                                Qt.callLater(function() {
                                    try {
                                        var finalPos = mpvPlayer.getProperty("time-pos");
                                        var finalFrame = Math.round(finalPos * fps);
                                        console.log("Final verification result: target=", targetFrame, "final=", finalFrame);
                                        
                                        // UI 업데이트
                                        root.frame = finalFrame;
                                        root.onFrameChangedEvent(finalFrame);
                                    } catch (e) {
                                        console.error("Final verification error:", e);
                                    }
                                });
                            }
                        } else {
                            console.log("Frame seek final confirmation complete:", targetFrame);
                        }
                    }
                } catch (e) {
                    console.error("Final verification timer error:", e);
                }
            }
        }
    }
    
    // 메타데이터 업데이트 차단 해제 타이머
    Timer {
        id: metadataBlockReleaseTimer
        interval: 800  // 드래그/시크 후 0.8초 동안 메타데이터 업데이트 차단
        repeat: false
        onTriggered: {
            console.log("Metadata update block released");
            metadataUpdateBlocked = false;
            
            // 지연된 메타데이터 가져오기가 필요한 경우 실행
            if (!metadataLoaded) {
                delayedMetadataTimer.restart();
            }
        }
    }
    
    // 지연된 메타데이터 가져오기 타이머
    Timer {
        id: delayedMetadataTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!metadataUpdateBlocked && !metadataLoaded) {
                console.log("Delayed metadata fetch executed (one time only)");
                fetchVideoMetadata();
                // 이후에는 메타데이터 로드 상태를 true로 유지
                metadataLoaded = true;
            } else {
                console.log("Metadata already loaded or blocked - skipping metadata update");
            }
        }
    }
    
    // 메타데이터 업데이트 차단 시간 확인 타이머 - 안전 장치
    Timer {
        id: metadataBlockTimeoutTimer
        interval: 10000  // 10초 후 강제 해제 (안전 장치)
        repeat: false
        running: metadataUpdateBlocked
        onTriggered: {
            // 메타데이터 업데이트 차단이 너무 오래 지속되면 강제로 해제
            if (metadataUpdateBlocked) {
                console.log("Metadata update block timeout - forced release");
                metadataUpdateBlocked = false;
                
                // 새 파일이 로드된 경우에만 메타데이터 가져오기 (아직 로드되지 않은 경우)
                if (!metadataLoaded) {
                    console.log("Initial metadata load needed - fetching after block release");
                    Qt.callLater(fetchVideoMetadata);
                }
            }
        }
    }
    
    // 메타데이터 업데이트 상태 관리 로직 추가 - 플레이어 상태에 따라 자동으로 차단/해제
    onIsPlayingChanged: {
        // 재생 중에는 메타데이터 업데이트 차단 (성능 향상)
        if (isPlaying) {
            if (!metadataUpdateBlocked) {
                console.log("Playback started: Metadata update block activated");
                metadataUpdateBlocked = true;
            }
        } else {
            // 정지 상태에서 일정 시간 후 메타데이터 업데이트 차단 해제
            // (사용자가 일시정지 버튼을 누른 경우에만)
            metadataUnblockTimer.restart();
        }
    }
    
    // 메타데이터 차단 해제 타이머 (일시정지 후 3초로 증가)
    Timer {
        id: metadataUnblockTimer
        interval: 3000  // 3초로 증가 (더 안정적인 렌더링을 위해)
        repeat: false
        running: false
        
        onTriggered: {
            if (!isPlaying && metadataUpdateBlocked) {
                console.log("After 3 seconds pause: Metadata update block released");
                metadataUpdateBlocked = false;
                
                // 필요한 경우 메타데이터 새로고침 (이미 로드된 경우 스킵)
                if (!metadataLoaded) {
                    console.log("Required metadata load started (for new video)");
                    fetchVideoMetadata();
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
    
    // Function to fetch and update video metadata
    function fetchVideoMetadata() {
        // 이미 메타데이터가 로드되었으면 스킵
        if (metadataLoaded) {
            console.log("Metadata already loaded. Preventing duplicate loading");
            return;
        }
        
        if (!mpvPlayer) {
            console.log("Cannot fetch metadata: mpvPlayer is null");
            return;
        }
        
        try {
            console.log("Attempting to fetch video metadata...");
            
            // Try to get all available properties for debugging first
            console.log("Getting available property list...");
            try {
                var props = mpvPlayer.getPropertyString("property-list");
                if (props) {
                    console.log("Available properties:", props);
                }
                
                // Also try to get tracks info which often has codec info
                var trackList = mpvPlayer.getProperty("track-list");
                if (trackList) {
                    console.log("Track list information:", JSON.stringify(trackList));
                }
            } catch (e) {
                console.log("Could not get property list:", e);
            }
            
            // Get codec information - try multiple approaches
            // 1. Try standard MPV property
            videoCodec = getVideoProperty("video-codec") || "";
            console.log("Video codec from video-codec:", videoCodec);
            
            // 2. If that fails, try video-params/codec
            if (!videoCodec) {
                videoCodec = getVideoProperty("video-params/codec") || "";
                console.log("Video codec from video-params/codec:", videoCodec);
            }
            
            // 3. If that fails, try getting from track-list
            if (!videoCodec) {
                try {
                    var tracks = mpvPlayer.getProperty("track-list");
                    if (tracks && Array.isArray(tracks)) {
                        for (var i = 0; i < tracks.length; i++) {
                            var track = tracks[i];
                            if (track.type === "video" && track.selected) {
                                if (track.codec) {
                                    videoCodec = track.codec;
                                    console.log("Video codec from track-list:", videoCodec);
                                    break;
                                }
                            }
                        }
                    }
                } catch (err) {
                    console.log("Error getting codec from track-list:", err);
                }
            }
            
            // 4. If that fails, try direct command to get format info
            if (!videoCodec) {
                try {
                    mpvPlayer.command(["script-message-to", "console", "format"]);
                    console.log("Requested format info via script message");
                } catch (err) {
                    console.log("Error requesting format info:", err);
                }
            }
            
            // Get video format
            videoFormat = getVideoProperty("video-format") || 
                          getVideoProperty("video-params/pixelformat") || 
                          getVideoProperty("video-params/hw-pixelformat") || "";
            console.log("Video format:", videoFormat);
            
            // Get video resolution - with fallbacks
            videoResolution = getVideoResolution();
            console.log("Video resolution:", videoResolution);
            
            videoBitrate = getVideoBitrate();
            console.log("Video bitrate:", videoBitrate);
            
            videoAspectRatio = getVideoProperty("video-aspect") || 
                               getVideoProperty("video-params/aspect") || 1.0;
            console.log("Video aspect ratio:", videoAspectRatio);
            
            videoColorSpace = getVideoProperty("video-params/colormatrix") || 
                             getVideoProperty("video-params/colorspace") || "";
            console.log("Video color space:", videoColorSpace);
            
            // Get audio information
            audioCodec = getVideoProperty("audio-codec") || "";
            console.log("Audio codec:", audioCodec);
            
            audioChannels = getVideoProperty("audio-channels") || 
                           getVideoProperty("audio-params/channels") || "";
            console.log("Audio channels:", audioChannels);
            
            audioSampleRate = getVideoProperty("audio-samplerate") ? 
                              (getVideoProperty("audio-samplerate") / 1000).toFixed(1) + " kHz" : 
                              (getVideoProperty("audio-params/samplerate") ? 
                              (getVideoProperty("audio-params/samplerate") / 1000).toFixed(1) + " kHz" : "");
            console.log("Audio sample rate:", audioSampleRate);
            
            // Get creation date (try multiple metadata sources)
            creationDate = getCreationDate();
            console.log("Creation date:", creationDate);
            
            // 메타데이터 로드 완료 표시
            metadataLoaded = true;
            console.log("Video metadata loading completed");
            
            // Emit signal that metadata changed
            root.onMetadataChanged();
            
            // 중복 로드 방지를 위해 추가 메타데이터 갱신 타이머 미사용
            // Schedule another metadata refresh after a short delay for reliability
            // Sometimes metadata isn't fully available on the first attempt
            if (!videoCodec) {
                console.log("Codec information not found, trying one more time");
                metadataLoaded = false; // 실패한 경우만 한 번 더 시도
                Qt.callLater(function() {
                    metadataRetryTimer.start();
                });
            }
        } catch (e) {
            console.error("Error fetching metadata:", e);
        }
    }
    
    // Helper function to safely get property from MPV
    function getVideoProperty(propertyName) {
        try {
            console.log("Trying to get property:", propertyName);
            
            // First check if mpvPlayer is valid
            if (!mpvPlayer) {
                console.log("Cannot get property: mpvPlayer is null");
                return null;
            }
            
            // Try direct property access first if available
            if (typeof mpvPlayer[propertyName] !== "undefined") {
                console.log("Direct property access for:", propertyName, "=", mpvPlayer[propertyName]);
                return mpvPlayer[propertyName];
            }
            
            // Check if getProperty method exists
            if (typeof mpvPlayer.getProperty === "function") {
                try {
                    var value = mpvPlayer.getProperty(propertyName);
                    console.log("Property", propertyName, "value:", value);
                    return value;
                } catch (e) {
                    console.log("Error getting property via getProperty:", e);
                }
            }
            
            // Fallback to getPropertyString if available
            if (typeof mpvPlayer.getPropertyString === "function") {
                try {
                    console.log("Trying getPropertyString instead");
                    return mpvPlayer.getPropertyString(propertyName);
                } catch (e) {
                    console.log("Error getting property via getPropertyString:", e);
                }
            }
            
            // Special case for common properties
            if (propertyName === "video-codec" && typeof mpvPlayer.videoCodec !== "undefined") {
                return mpvPlayer.videoCodec;
            }
            
            if (propertyName === "fps" && typeof mpvPlayer.fps !== "undefined") {
                return mpvPlayer.fps;
            }
            
            console.log("No method available to get property:", propertyName);
            return null;
        } catch (e) {
            console.log("Error getting property", propertyName + ":", e.toString());
            return null;
        }
    }
    
    // Helper to get video resolution
    function getVideoResolution() {
        try {
            const width = getVideoProperty("width") || getVideoProperty("video-params/w") || 0;
            const height = getVideoProperty("height") || getVideoProperty("video-params/h") || 0;
            if (width && height) {
                return width + "×" + height;
            }
            return "";
        } catch (e) {
            return "";
        }
    }
    
    // Helper to get video bitrate in a nice format
    function getVideoBitrate() {
        try {
            const bitrate = getVideoProperty("video-bitrate") || 0;
            if (bitrate > 0) {
                if (bitrate >= 1000000) {
                    return (bitrate / 1000000).toFixed(2) + " Mbps";
                } else {
                    return (bitrate / 1000).toFixed(0) + " kbps";
                }
            }
            return "";
        } catch (e) {
            return "";
        }
    }
    
    // Helper to get creation date from various metadata fields
    function getCreationDate() {
        try {
            // Try different metadata fields where date might be stored
            const dateFields = [
                "creation_time",             // Common field
                "metadata/creation_time",    // In metadata object
                "file-creation-time",        // File system date
                "metadata/date",             // Generic date field
                "metadata/creation_date"     // Alternative name
            ];
            
            for (let i = 0; i < dateFields.length; i++) {
                const dateValue = getVideoProperty(dateFields[i]);
                if (dateValue) {
                    // Try to parse and format the date
                    try {
                        const date = new Date(dateValue);
                        if (!isNaN(date.getTime())) {
                            return date.toISOString().split('T')[0]; // YYYY-MM-DD format
                        }
                        return dateValue; // Return as is if can't parse
                    } catch (e) {
                        return dateValue; // Return as is if error
                    }
                }
            }
            
            // Fallback to current date if no metadata date found
            const currentDate = new Date();
            return currentDate.toISOString().split('T')[0]; // YYYY-MM-DD format
        } catch (e) {
            console.error("Error getting creation date:", e);
            return "";
        }
    }
    
    // Timer to fetch metadata after file is loaded
    Timer {
        id: metadataFetchTimer
        interval: 300 // 300ms로 단축 (파일 로드 후 메타데이터 가져오기)
        repeat: false
        onTriggered: {
            console.log("Metadata fetch timer executed");
            fetchVideoMetadata();
            
            // 첫 번째 시도가 실패한 경우 추가 시도
            if (!metadataLoaded) {
                Qt.callLater(function() {
                    console.log("Additional metadata timer attempt");
                    fetchVideoMetadata();
                });
            }
        }
    }
    
    // Additional retry timer for metadata
    Timer {
        id: metadataRetryTimer
        interval: 1000  // 1초로 단축
        repeat: false
        onTriggered: {
            console.log("Metadata retry timer executed");
            fetchVideoMetadata();
        }
    }
}
