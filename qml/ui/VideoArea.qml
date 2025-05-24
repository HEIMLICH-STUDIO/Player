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
                        
                        // 파일 로드 시에만 메타데이터 가져오기 - 일시정지 상태에서만
                        metadataUpdateBlocked = false; // 로드 직후 차단 해제
                        Qt.callLater(function() {
                            if (!isPlaying) {
                                console.log("VideoArea: Initial metadata fetch called in paused state");
                                fetchVideoMetadata();
                            } else {
                                console.log("VideoArea: Skipping initial metadata fetch in playing state");
                            }
                        });
                    });
                    console.log("VideoArea: fileLoaded signal connection successful");
                }
                
                // 추가적인 이벤트 연결
                mpvPlayer.frameCountChanged.connect(function(frames) {
                    root.frames = frames;
                    root.onTotalFramesChangedEvent(frames);
                });
                
                mpvPlayer.pauseChanged.connect(function(paused) {
                    console.log("VideoArea: Pause changed:", paused);
                    root.isPlaying = !paused;
                    root.onIsPlayingChangedEvent(!paused);
                    
                    // 일시정지 상태에서만 메타데이터 가져오기 허용
                    if (paused && !metadataLoaded) {
                        metadataUnblockTimer.restart(); // 일시정지 3초 후에 메타데이터 가져오기
                    } else if (!paused) {
                        // 재생 중에는 메타데이터 업데이트 차단
                        metadataUpdateBlocked = true;
                    }
                });
                
                mpvPlayer.playingChanged.connect(function(playing) {
                    console.log("VideoArea: Playing changed:", playing);
                    root.isPlaying = playing;
                    root.onIsPlayingChangedEvent(playing);
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
                        
                        // EOF 복구 중인 경우 복구 완료 처리
                        if (eofRecoveryTimer.running) {
                            console.log("VideoArea: File reload detected during EOF recovery");
                            // 파일 로드가 감지되면 복구 타이머는 계속 진행
                        }
                        
                        // 파일 변경 시에는 메타데이터 가져오기를 자동으로 하지 않음
                        // fileLoaded 이벤트에서 처리됨
                    }
                });
            } catch (e) {
                console.error("VideoArea: Event connection error:", e);
            }
        }
    }
    
    // 영상 끝 감지 핸들러
    Connections {
        target: mpvPlayer
        function onPositionChanged(position) {
            // 영상 끝 근처 감지 로직
            if (mpvPlayer && position > 0) {
                var duration = mpvPlayer.getProperty("duration");
                if (duration && duration > 0) {
                    // 마지막 1초 이내에서 영상 끝 플래그 설정
                    if (position > duration - 1.0 && !isNearEndOfFile) {
                        console.log("VideoArea: Near end of file detected at position:", position);
                        isNearEndOfFile = true;
                    }
                    // 마지막 0.1초 이내에서 완전 끝 플래그 설정
                    else if (position > duration - 0.1 && !isAtEndOfFile) {
                        console.log("VideoArea: At end of file detected at position:", position);
                        isAtEndOfFile = true;
                    }
                    // 앞부분으로 돌아가면 플래그 리셋 (더 빠른 리셋)
                    else if (position < duration - 1.5 && (isNearEndOfFile || isAtEndOfFile)) {
                        console.log("VideoArea: Reset end flags, position:", position);
                        isNearEndOfFile = false;
                        isAtEndOfFile = false;
                    }
                    
                    // 특별한 경우: 시작 부분(첫 2초)으로 이동하면 즉시 플래그 리셋
                    if (position < 2.0 && (isNearEndOfFile || isAtEndOfFile)) {
                        console.log("VideoArea: Position near start - force reset end flags");
                        isNearEndOfFile = false;
                        isAtEndOfFile = false;
                    }
                }
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
                        
                        // 프레임 범위 검증 - 타임라인과 동기화 문제 방지
                        if (root.frames > 0 && frame >= root.frames) {
                            console.warn("MPV Sync: Frame number out of range:", frame, "max:", root.frames-1);
                            frame = root.frames - 1;
                        }
                        
                        // console.log("MPV Sync: Frame change detected from video area:", frame);
                        root.frame = frame;
                        root.onFrameChangedEvent(frame);
                    }
                });
                
                mpvPlayer.durationChanged.connect(function(duration) {
                    // Update total frame count
                    if (duration > 0 && root.fps > 0) {
                        // 실제 프레임 수 계산 (171개 프레임)
                        var totalFrames = Math.ceil(duration * root.fps) - 1;
                        console.log("MPV Sync: Duration changed, calculating frames:", 
                                   "duration =", duration, 
                                   "fps =", root.fps, 
                                   "calculated frames =", totalFrames);
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
                        
                        // 파일 변경 시에는 메타데이터 가져오기를 자동으로 하지 않음
                        // fileLoaded 이벤트에서 처리됨
                    }
                });
                
                // Connect to file-loaded event if available
                if (mpvPlayer.hasOwnProperty('fileLoaded')) {
                    mpvPlayer.fileLoaded.connect(function() {
                        console.log("File fully loaded, fetching metadata");
                        metadataLoaded = false; // 확실히 초기화
                        
                        // 영상 끝 플래그 리셋 (파일 로드 시)
                        isNearEndOfFile = false;
                        isAtEndOfFile = false;
                        
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
                
                mpvPlayer.fpsChanged.connect(function(fps) {
                    if (fps > 0) {
                        root.fps = fps;
                        root.onFpsChangedEvent(fps);
                        
                        // When FPS changes, update total frame count as well
                        if (mpvPlayer.duration > 0) {
                            var totalFrames = Math.ceil(mpvPlayer.duration * root.fps) - 1;
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
                // 현재 위치가 끝에 가까운지 확인
                var duration = mpvPlayer.getProperty("duration");
                var position = mpvPlayer.getProperty("time-pos");
                var isNearEnd = false;
                
                // 비디오 끝 근처인지 확인 (끝에서 0.5초 이내)
                if (duration > 0 && position > 0) {
                    isNearEnd = (duration - position) < 0.5;
                }
                
                // EOF에 도달했거나 끝에 매우 가까우면 처음으로 돌아가기
                if (isNearEnd || isAtEndOfFile || (mpvPlayer.hasOwnProperty('endReached') && mpvPlayer.endReached)) {
                    console.log("End of video detected - restarting from beginning");
                    
                    // EOF 플래그 리셋
                    isNearEndOfFile = false;
                    isAtEndOfFile = false;
                    
                    // 비디오 시작 부분으로 시크
                    mpvPlayer.setProperty("pause", true);
                    mpvPlayer.setProperty("time-pos", 0.0);
                    
                    // 내부 상태 업데이트
                    root.frame = 0;
                    root.onFrameChangedEvent(0);
                    
                    // 약간의 지연 후 재생 시작 (시크 완료 보장)
                    Qt.callLater(function() {
                        mpvPlayer.setProperty("pause", false);
                        isPlaying = true;
                        onIsPlayingChangedEvent(true);
                    });
                } else {
                    // 일반적인 재생/일시정지 전환
                    mpvPlayer.playPause();
                    isPlaying = !mpvPlayer.pause;
                    onIsPlayingChangedEvent(isPlaying);
                }
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
                // 1. 먼저 일시정지 상태로 변경 (EOF 안전 처리)
                try {
                if (!mpvPlayer.pause) {
                        mpvPlayer.setProperty("pause", true);
                    }
                } catch (pauseError) {
                    console.warn("Cannot set pause property directly, trying command:", pauseError);
                    try {
                        mpvPlayer.command(["set", "pause", "yes"]);
                    } catch (cmdError) {
                        console.error("Both pause methods failed:", cmdError);
                    }
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
                // 1. 먼저 일시정지 상태로 변경 (EOF 안전 처리)
                try {
                if (!mpvPlayer.pause) {
                        mpvPlayer.setProperty("pause", true);
                    }
                } catch (pauseError) {
                    console.warn("Cannot set pause property directly, trying command:", pauseError);
                    try {
                        mpvPlayer.command(["set", "pause", "yes"]);
                    } catch (cmdError) {
                        console.error("Both pause methods failed:", cmdError);
                    }
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
    
    // 특정 프레임으로 이동
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
                
                // 2. 프레임 범위 확인 및 엄격한 검증
                if (targetFrame < 0) {
                    console.warn("Invalid frame (negative):", targetFrame, "correcting to 0");
                    targetFrame = 0;
                }
                
                if (root.frames > 0 && targetFrame >= root.frames) {
                    console.warn("Invalid frame (too large):", targetFrame, "max:", root.frames-1);
                    targetFrame = root.frames - 1;
                }
                
                // 3. EOF 상태 감지 및 특별 처리 (더 넓은 감지 범위)
                var currentPos = mpvPlayer.getProperty("time-pos");
                var duration = mpvPlayer.getProperty("duration");
                var isAtEOF = false;
                
                // EOF 감지 조건을 더 넓게 설정 (마지막 2초 이내 또는 EOF 플래그)
                if (currentPos && duration && 
                    (currentPos > duration - 2.0 || 
                     isNearEndOfFile || 
                     isAtEndOfFile ||
                     (root.frames > 0 && root.frame >= root.frames - 3))) {
                    isAtEOF = true;
                    eofRecoveryFailCount++; // 실패 카운터 증가
                    
                    console.log("VideoArea: Detected EOF state (attempt", eofRecoveryFailCount + "/" + maxEofRecoveryAttempts + ")");
                    
                    // 실패 횟수가 너무 많으면 강제 초기화
                    if (eofRecoveryFailCount >= maxEofRecoveryAttempts) {
                        console.log("VideoArea: Max EOF recovery attempts reached - FORCING COMPLETE RESET");
                        forceCompleteReset(targetFrame);
                        return true;
                    }
                    
                    // EOF에서 벗어나기 위한 더 강력한 처리
                    try {
                        // 1. 먼저 일시정지 강제 설정
                        mpvPlayer.setProperty("pause", true);
                        
                        // 2. 파일 재로드로 EOF 상태 완전 초기화
                        var currentFile = mpvPlayer.getProperty("filename");
                        if (currentFile) {
                            console.log("VideoArea: Reloading file to escape EOF:", currentFile);
                            mpvPlayer.command(["loadfile", currentFile]);
                            
                            // 3. 파일 로드 후 목표 프레임으로 시크 예약
                            eofRecoveryTimer.targetFrame = targetFrame;
                            eofRecoveryTimer.restart();
                            
                            return true;
                        } else {
                            // 파일명을 가져올 수 없으면 다른 방법 시도
                            console.log("VideoArea: Cannot get filename, trying alternative EOF recovery");
                            performAlternativeEOFRecovery(targetFrame);
                            return true;
                        }
                    } catch (e) {
                        console.error("VideoArea: EOF recovery failed:", e);
                        // 최후의 수단으로 대체 방법 시도
                        performAlternativeEOFRecovery(targetFrame);
                        return true;
                    }
                } else {
                    // EOF 상태가 아니면 카운터 리셋
                    if (eofRecoveryFailCount > 0) {
                        console.log("VideoArea: EOF recovery successful - resetting fail counter");
                        eofRecoveryFailCount = 0;
                    }
                }
                
                // 4. 프레임 번호 조정 (항상 1-based 사용)
                // 0번 프레임을 1번으로 조정, 그 외는 인덱스 +1
                var adjustedFrame = Math.max(1, targetFrame + 1);
                if (targetFrame === 0) {
                    console.log("프레임 인덱스 조정: 0 -> 1 (1-based 인덱싱 적용)");
                }
                
                // 5. 타임스탬프 계산 및 MPV 오류 방지를 위한 명확한 숫자 형식 지정
                var timePos = (adjustedFrame - 1) / fps; // 0-based 시간 위치 계산
                var numericPos = Number(timePos.toFixed(6)); // 명시적 숫자로 변환
                
                console.log("MPV direct seek command:", numericPos, "(프레임:", adjustedFrame, ")");
                
                // 6. 항상 일시정지 상태로 변경 - 정확한 프레임 포지셔닝 위해
                mpvPlayer.setProperty("pause", true);
                
                // 7. MPV 안전한 시크 구현 - 속성 설정만 사용
                mpvPlayer.setProperty("time-pos", numericPos);
                
                // 8. 내부 프레임 즉시 업데이트 (UI 응답성)
                root.frame = targetFrame;
                root.onFrameChangedEvent(targetFrame);
                
                // 9. 프레임 동기화 검증 - 지연 후 실행
                Qt.callLater(function() {
                    syncMpvAndUiFrames(targetFrame);
                });
                
                // 10. 메타데이터 업데이트 차단 해제 예약
                metadataBlockReleaseTimer.restart();
                
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
    
    // EOF 복구 타이머 (파일 재로드 후 시크)
    Timer {
        id: eofRecoveryTimer
        interval: 1000  // 파일 로드 후 1초 대기
        repeat: false
        property int targetFrame: 0
        
        onTriggered: {
            if (mpvPlayer) {
                try {
                    console.log("VideoArea: EOF recovery - seeking to target frame after reload:", targetFrame);
                    
                    // 파일이 로드된 후 목표 프레임으로 시크
                    var adjustedFrame = Math.max(1, targetFrame + 1);
                    var timePos = (adjustedFrame - 1) / fps;
                    var numericPos = Number(timePos.toFixed(6));
                    
                    // 일시정지 상태에서 시크
                    mpvPlayer.setProperty("pause", true);
                    mpvPlayer.setProperty("time-pos", numericPos);
                    
                    // 내부 상태 업데이트
                    root.frame = targetFrame;
                    root.onFrameChangedEvent(targetFrame);
                    
                    // EOF 플래그 리셋
                    isNearEndOfFile = false;
                    isAtEndOfFile = false;
                    
                    console.log("VideoArea: EOF recovery completed - frame:", targetFrame);
                    
                } catch (e) {
                    console.error("VideoArea: EOF recovery timer error:", e);
                }
            }
            
            // 메타데이터 업데이트 차단 해제
            metadataUpdateBlocked = false;
        }
    }
    
    // 대체 EOF 복구 함수 (파일 재로드가 실패할 경우)
    function performAlternativeEOFRecovery(targetFrame) {
        try {
            console.log("VideoArea: Attempting alternative EOF recovery for frame:", targetFrame);
            
            // 1. 강력한 EOF 탈출 시도
            try {
                // EOF 플래그 강제 해제
                mpvPlayer.command(["set", "eof-reached", "no"]);
            } catch (e) {
                console.log("VideoArea: Cannot clear EOF flag:", e);
            }
            
            // 2. 여러 MPV 속성을 순차적으로 리셋 시도
            try {
                mpvPlayer.setProperty("pause", true);
            } catch (e) {
                try {
                    mpvPlayer.command(["set", "pause", "yes"]);
                } catch (e2) {
                    console.error("VideoArea: Cannot pause player:", e2);
                }
            }
            
            // 3. 강제로 처음 위치로 리셋 (여러 방법 시도)
            var resetSuccess = false;
            
            // 방법 1: 직접 시간 위치 설정
            try {
                mpvPlayer.setProperty("time-pos", 0.0);
                mpvPlayer.setProperty("time-start", 0.0);
                resetSuccess = true;
                console.log("VideoArea: Reset to start using time-pos");
            } catch (e1) {
                // 방법 2: 시크 명령 (exact)
                try {
                    mpvPlayer.command(["seek", "0", "absolute", "exact"]);
                    resetSuccess = true;
                    console.log("VideoArea: Reset to start using seek exact");
                } catch (e2) {
                    // 방법 3: 일반 시크 명령
                    try {
                        mpvPlayer.command(["seek", "0", "absolute"]);
                        resetSuccess = true;
                        console.log("VideoArea: Reset to start using seek normal");
                    } catch (e3) {
                        // 방법 4: 위치 백분율로 시크
                        try {
                            mpvPlayer.command(["seek", "0", "absolute-percent"]);
                            resetSuccess = true;
                            console.log("VideoArea: Reset to start using percent");
                        } catch (e4) {
                            console.error("VideoArea: All reset methods failed");
                        }
                    }
                }
            }
            
            // 4. 강제 프레임 번호 리셋
            root.frame = 0;
            root.onFrameChangedEvent(0);
            
            // 5. EOF 플래그 리셋
            isNearEndOfFile = false;
            isAtEndOfFile = false;
            
            // 6. 지연 후 목표 프레임으로 시크 시도
            if (resetSuccess) {
                alternativeRecoveryTimer.targetFrame = targetFrame;
                alternativeRecoveryTimer.restart();
            } else {
                // 모든 방법이 실패하면 강제 UI 업데이트만
                console.log("VideoArea: All methods failed, forcing UI update only");
                forceUIUpdate(targetFrame);
            }
            
        } catch (e) {
            console.error("VideoArea: Alternative EOF recovery failed:", e);
            // 최후의 수단: 강제 UI 업데이트
            forceUIUpdate(targetFrame);
        }
    }
    
    // 강제 UI 업데이트 함수 (MPV가 완전히 응답하지 않을 때)
    function forceUIUpdate(targetFrame) {
        console.log("VideoArea: Forcing UI update to frame:", targetFrame);
        
        // UI 상태만 강제로 업데이트
        root.frame = targetFrame;
        root.onFrameChangedEvent(targetFrame);
        
        // EOF 플래그 강제 리셋
        isNearEndOfFile = false;
        isAtEndOfFile = false;
        
        // 메타데이터 차단 해제
        metadataUpdateBlocked = false;
        
        // 사용자에게 알림
        showMessage("Frame position updated (MPV may be unresponsive)");
    }
    
    // 강제 완전 리셋 함수 (모든 복구 방법이 실패했을 때의 최후 수단)
    function forceCompleteReset(targetFrame) {
        console.log("VideoArea: *** EMERGENCY RESET *** - All recovery methods failed, performing complete reset");
        
        try {
            // 1단계: 모든 타이머 중지
            eofRecoveryTimer.stop();
            alternativeRecoveryTimer.stop();
            secondSeekTimer.stop();
            finalVerifyTimer.stop();
            metadataBlockReleaseTimer.stop();
            
            // 2단계: 모든 상태 플래그 강제 리셋
            isNearEndOfFile = false;
            isAtEndOfFile = false;
            metadataUpdateBlocked = false;
            eofRecoveryFailCount = 0; // 카운터 리셋
            
            // 3단계: MPV 강제 정지 및 리셋 시도
            try {
                console.log("VideoArea: Emergency - stopping all MPV operations");
                mpvPlayer.command(["stop"]);
            } catch (e) {
                console.log("VideoArea: MPV stop failed:", e);
            }
            
            // 4단계: 현재 파일 재로드 시도
            var currentFile = root.filename;
            if (currentFile && currentFile !== "") {
                console.log("VideoArea: Emergency - reloading file:", currentFile);
                
                // 파일 재로드
                try {
                    mpvPlayer.command(["loadfile", currentFile, "replace"]);
                    
                    // 재로드 후 목표 위치로 시크하는 타이머 예약
                    emergencyRecoveryTimer.targetFrame = targetFrame;
                    emergencyRecoveryTimer.restart();
                    
                    console.log("VideoArea: Emergency file reload initiated, target frame:", targetFrame);
                    return;
                } catch (e) {
                    console.error("VideoArea: Emergency file reload failed:", e);
                }
            }
            
            // 5단계: 파일 재로드도 실패하면 처음 위치로 강제 이동
            console.log("VideoArea: Emergency - forcing reset to frame 0");
            try {
                mpvPlayer.setProperty("pause", true);
                mpvPlayer.setProperty("time-pos", 0.0);
                
                // UI 즉시 업데이트
                root.frame = 0;
                root.onFrameChangedEvent(0);
                
                showMessage("Video reset to beginning due to playback issues");
                
            } catch (e) {
                console.error("VideoArea: Emergency reset to frame 0 failed:", e);
                
                // 6단계: 최후의 수단 - UI만 강제 업데이트
                console.log("VideoArea: Last resort - UI-only reset");
                root.frame = Math.max(0, Math.min(targetFrame, root.frames - 1));
                root.onFrameChangedEvent(root.frame);
                
                showMessage("Emergency: UI reset only (video player unresponsive)");
            }
            
        } catch (e) {
            console.error("VideoArea: Complete emergency reset failed:", e);
            
            // 절대 최후의 수단: UI 상태만 리셋
            root.frame = 0;
            root.onFrameChangedEvent(0);
            isNearEndOfFile = false;
            isAtEndOfFile = false;
            metadataUpdateBlocked = false;
            eofRecoveryFailCount = 0;
            
            showMessage("Critical error: Video player requires restart");
        }
    }
    
    // 대체 복구 타이머
    Timer {
        id: alternativeRecoveryTimer
        interval: 500
        repeat: false
        property int targetFrame: 0
        
        onTriggered: {
            if (mpvPlayer) {
                try {
                    console.log("VideoArea: Alternative recovery - seeking to frame:", targetFrame);
                    
                    var adjustedFrame = Math.max(1, targetFrame + 1);
                    var timePos = (adjustedFrame - 1) / fps;
                    var numericPos = Number(timePos.toFixed(6));
                    
                    // 강제로 내부 상태 업데이트 (MPV가 응답하지 않아도)
                    root.frame = targetFrame;
                    root.onFrameChangedEvent(targetFrame);
                    
                    // EOF 플래그 강제 리셋
                    isNearEndOfFile = false;
                    isAtEndOfFile = false;
                    
                    console.log("VideoArea: Alternative recovery forced update to frame:", targetFrame);
                    
                } catch (e) {
                    console.error("VideoArea: Alternative recovery timer error:", e);
                }
            }
            
            metadataUpdateBlocked = false;
        }
    }
    
    // 비상 복구 타이머 (강제 파일 재로드 후 시크)
    Timer {
        id: emergencyRecoveryTimer
        interval: 2000  // 파일 재로드를 위해 2초 대기
        repeat: false
        property int targetFrame: 0
        
        onTriggered: {
            if (mpvPlayer) {
                try {
                    console.log("VideoArea: Emergency recovery - seeking to target frame after complete reload:", targetFrame);
                    
                    // 일시정지 상태 확인
                    mpvPlayer.setProperty("pause", true);
                    
                    // 안전한 프레임으로 시크 (처음이 아닌 경우)
                    if (targetFrame > 0 && targetFrame < root.frames - 5) {
                        var adjustedFrame = Math.max(1, targetFrame + 1);
                        var timePos = (adjustedFrame - 1) / fps;
                        var numericPos = Number(timePos.toFixed(6));
                        
                        mpvPlayer.setProperty("time-pos", numericPos);
                        console.log("VideoArea: Emergency recovery - sought to frame:", targetFrame);
                    } else {
                        // 문제가 있는 프레임이면 처음으로
                        mpvPlayer.setProperty("time-pos", 0.0);
                        targetFrame = 0;
                        console.log("VideoArea: Emergency recovery - reset to frame 0 for safety");
                    }
                    
                    // UI 상태 업데이트
                    root.frame = targetFrame;
                    root.onFrameChangedEvent(targetFrame);
                    
                    // 모든 플래그 리셋
                    isNearEndOfFile = false;
                    isAtEndOfFile = false;
                    metadataUpdateBlocked = false;
                    eofRecoveryFailCount = 0; // 성공했으므로 카운터 리셋
                    
                    console.log("VideoArea: Emergency recovery completed successfully");
                    showMessage("Video successfully recovered from playback error");
                    
                } catch (e) {
                    console.error("VideoArea: Emergency recovery timer failed:", e);
                    
                    // 마지막 시도: UI만 업데이트
                    root.frame = 0;
                    root.onFrameChangedEvent(0);
                    isNearEndOfFile = false;
                    isAtEndOfFile = false;
                    metadataUpdateBlocked = false;
                    eofRecoveryFailCount = 0;
                    
                    showMessage("Recovery partially successful - UI reset only");
                }
            }
        }
    }
    
    // 영상 끝 감지 플래그
    property bool isNearEndOfFile: false
    property bool isAtEndOfFile: false
    
    // EOF 복구 실패 카운터 (무한 루프 방지)
    property int eofRecoveryFailCount: 0
    property int maxEofRecoveryAttempts: 3
    
    // 새로운 함수: MPV와 UI 프레임 동기화 (영상 끝에서 비활성화)
    function syncMpvAndUiFrames(targetFrame) {
        if (!mpvPlayer) return;
        
        // 영상 끝에서는 동기화 중단
        if (isNearEndOfFile || isAtEndOfFile) {
            console.log("Sync mediator: Near/at end of file - sync disabled");
            return;
        }
        
        try {
            var actualPos = mpvPlayer.getProperty("time-pos");
            if (actualPos !== undefined && actualPos !== null) {
                // 영상 끝 근처 감지 (마지막 1초 이내)
                var duration = mpvPlayer.getProperty("duration");
                if (duration && actualPos > duration - 1.0) {
                    console.log("Sync mediator: Near end detected - disabling sync");
                    isNearEndOfFile = true;
                    return;
                }
                
                // MPV의 실제 프레임 계산 (시간 -> 프레임)
                var rawMpvFrame = Math.round(actualPos * fps);
                var actualFrame = rawMpvFrame;
                
                // 마지막 5프레임 이내에서는 동기화 중단
                if (root.frames > 0 && actualFrame >= root.frames - 5) {
                    console.log("Sync mediator: Near final frames - disabling sync");
                    isNearEndOfFile = true;
                    return;
                }
                
                // 정상적인 범위인지 확인
                if (actualFrame < 0 || (root.frames > 0 && actualFrame >= root.frames)) {
                    console.warn("Sync mediator: Invalid MPV frame detected:", actualFrame);
                    return;
                }
                
                console.log("Sync mediator: MPV raw frame=", rawMpvFrame, ", adjusted frame=", actualFrame, ", UI frame=", targetFrame);
                
                // MPV와 UI 프레임 차이 로깅만 (강제 동기화 완전 비활성화)
                if (Math.abs(actualFrame - targetFrame) > 10) {
                    console.log("Sync mediator: Frame difference detected - MPV:", actualFrame, "UI:", targetFrame);
                    console.log("Sync mediator: 사용자 시크 우선 - MPV 동기화 생략");
                    
                    // *** 중요: 강제 동기화 완전 제거 - 사용자 시크 우선 처리 ***
                    // 더 이상 MPV 프레임으로 UI를 강제 업데이트하지 않음
                    return;
                }
            }
        } catch (e) {
            console.error("Sync mediator error:", e);
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
                    // 명확한 숫자 형식으로 변환 (MPV 오류 방지)
                    var numericPos = Number(timePos.toFixed(6));
                    
                    // 안전하게 속성 직접 설정 - 명령 대신
                    mpvPlayer.setProperty("pause", true);
                    mpvPlayer.setProperty("time-pos", numericPos);
                    
                    // 현재 프레임 상태 재확인 및 시그널 발생
                    var actualPos = mpvPlayer.getProperty("time-pos");
                    if (actualPos !== undefined && actualPos !== null) {
                        var actualFrame = Math.round(actualPos * fps);
                        console.log("Second verification: requested=", targetFrame, "actual=", actualFrame);
                        
                        if (Math.abs(actualFrame - targetFrame) > 2) {
                            console.log("Frame still mismatched, performing second correction");
                            
                            // MPV 상태에 맞추어 UI 업데이트 (실제 상태에 맞춤)
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
                    mpvPlayer.setProperty("pause", true);
                    var actualPos = mpvPlayer.getProperty("time-pos");
                    if (actualPos !== undefined && actualPos !== null) {
                        var actualFrame = Math.round(actualPos * fps);
                        console.log("Verification: MPV frame=", actualFrame, "_internalFrame=", targetFrame);
                        
                        // 여전히 불일치가 있는지 확인 (2프레임 이상 차이 시)
                        if (Math.abs(actualFrame - targetFrame) > 2) {
                            console.log("Frame mismatch detected - synchronizing");
                            
                            // MPV의 실제 상태를 기준으로 UI 동기화
                            root.frame = actualFrame;
                            root.onFrameChangedEvent(actualFrame);
                            
                            // 최종 확인 메시지
                            console.log("Frame seek final confirmation complete:", actualFrame);
                            console.log("Stabilization period ended");
                        } else {
                            console.log("Frame seek final confirmation complete:", targetFrame);
                            console.log("Stabilization period ended");
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
    
    // Timers for metadata handling
    Timer {
        id: delayedMetadataTimer
        interval: 500
        repeat: false
        running: false
        onTriggered: {
            // 지연된 메타데이터 로드 - 파일 로드 직후 처음 한 번만 사용
            if (!metadataLoaded) {
                console.log("Delayed metadata fetch triggered");
                fetchVideoMetadata();
            }
        }
    }
    
    // 메타데이터 가져오기 타이머 - 백업용 (fileLoaded 이벤트 대체용)
    Timer {
        id: metadataFetchTimer
        interval: 1000
        repeat: false
        running: false
        onTriggered: {
            if (!metadataLoaded) {
                console.log("Backup metadata fetch timer triggered");
                fetchVideoMetadata();
            }
        }
    }
    
    // 메타데이터 차단 해제 타이머 (일시정지 후 3초로 증가)
    Timer {
        id: metadataUnblockTimer
        interval: 3000
        repeat: false
        running: false
        onTriggered: {
            if (!isPlaying) {
                console.log("Playback stopped for 3 seconds: Metadata update block released");
                metadataUpdateBlocked = false;
                
                // 메타데이터가 아직 로드되지 않았으면 로드 (첫 파일 로드 시에만)
                if (!metadataLoaded) {
                    fetchVideoMetadata();
                }
            }
        }
    }
    
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
            console.log("Playback started: Metadata update block activated");
            metadataUpdateBlocked = true;
            
            // 모든 메타데이터 관련 타이머 중지
            if (metadataFetchTimer.running) metadataFetchTimer.stop();
            if (delayedMetadataTimer.running) delayedMetadataTimer.stop();
            if (metadataUnblockTimer.running) metadataUnblockTimer.stop();
        } else {
            // 정지 상태에서 일정 시간 후 메타데이터 업데이트 차단 해제
            // (사용자가 일시정지 버튼을 누른 경우에만)
            metadataUnblockTimer.restart();
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
            console.log("ControlBar: Metadata already loaded, preventing duplicate loading");
            return;
        }
        
        if (!mpvPlayer) {
            console.log("Cannot fetch metadata: mpvPlayer is null");
            return;
        }
        
        // 메타데이터 업데이트가 차단된 상태면 스킵
        if (metadataUpdateBlocked) {
            console.log("Metadata update blocked - not fetching metadata");
            return;
        }
        
        // 재생 중이면 메타데이터 가져오기 취소
        if (isPlaying) {
            console.log("Video is playing - skipping metadata fetch");
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
            
            // 메타데이터 로드 완료 후 더 이상 메타데이터 타이머 사용 안함
            if (metadataFetchTimer.running) {
                metadataFetchTimer.stop();
            }
            if (delayedMetadataTimer.running) {
                delayedMetadataTimer.stop();
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
}
