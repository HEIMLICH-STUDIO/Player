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
                        
                        // 즉시 메타데이터 가져오기 시도
                        fetchVideoMetadata();
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
    
    // 재생/일시정지 토글 - 단순화
    function playPause() {
        if (mpvPlayer) {
            try {
                // 현재 위치가 끝에 가까운지 확인
                var duration = mpvPlayer.getProperty("duration");
                var position = mpvPlayer.getProperty("time-pos");
                
                // 비디오 끝 근처인지 확인 (끝에서 0.5초 이내)
                if (duration > 0 && position > 0 && (duration - position) < 0.5) {
                    console.log("End of video detected - restarting from beginning");
                    
                    // 비디오 시작 부분으로 시크
                    mpvPlayer.setProperty("pause", true);
                    mpvPlayer.command(["seek", "0", "absolute", "exact"]);
                    
                    // 내부 상태 업데이트
                    root.frame = 0;
                    root.onFrameChangedEvent(0);
                    
                    // 약간의 지연 후 재생 시작
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
    
    // 프레임 앞으로 이동 - seekToPosition 사용
    function stepForward(frames) {
        if (!frames || frames < 1) frames = 1;
        
        if (mpvPlayer && fps > 0) {
            var currentPos = mpvPlayer.getProperty("time-pos") || 0;
            var frameTime = frames / fps;
            var targetPos = currentPos + frameTime;
            
            seekToPosition(targetPos);
            console.log("Step forward:", frames, "frames to position:", targetPos);
        }
    }
    
    // 프레임 뒤로 이동 - seekToPosition 사용
    function stepBackward(frames) {
        if (!frames || frames < 1) frames = 1;
        
        if (mpvPlayer && fps > 0) {
            var currentPos = mpvPlayer.getProperty("time-pos") || 0;
            var frameTime = frames / fps;
            var targetPos = Math.max(0, currentPos - frameTime);
            
            seekToPosition(targetPos);
            console.log("Step backward:", frames, "frames to position:", targetPos);
        }
    }
    
    // MPV 공식 권장 시간 기반 시크 함수 - EOF 상태 처리 강화
    function seekToPosition(targetPosition) {
        if (mpvPlayer) {
            try {
                console.log("VideoArea: MPV time-based seek to:", targetPosition);
                
                // 메타데이터 업데이트 차단 설정
                metadataUpdateBlocked = true;
                
                // 1. 시간 범위 검증
                var duration = mpvPlayer.getProperty("duration") || 0;
                if (duration > 0) {
                    targetPosition = Math.max(0.0, Math.min(targetPosition, duration - 0.1));
                }
                
                // 2. EOF 상태 감지 및 해제
                var currentPos = mpvPlayer.getProperty("time-pos") || 0;
                var isNearEOF = (duration > 0 && currentPos > duration - 1.0);
                
                if (isNearEOF) {
                    console.log("VideoArea: EOF detected, clearing EOF state before seek");
                    
                    // EOF 상태 강제 해제 방법들
                    try {
                        // 방법 1: EOF 플래그 직접 해제
                        mpvPlayer.setProperty("eof-reached", false);
                    } catch (e) {
                        console.log("Cannot clear eof-reached property:", e);
                    }
                    
                    try {
                        // 방법 2: 재생 위치를 안전한 곳으로 먼저 이동
                        var safePos = Math.max(0, duration - 2.0);
                        mpvPlayer.setProperty("time-pos", safePos);
                        console.log("VideoArea: Moved to safe position:", safePos);
                    } catch (e) {
                        console.log("Cannot set safe position:", e);
                    }
                }
                
                // 3. 일시정지 상태로 변경
                mpvPlayer.setProperty("pause", true);
                
                // 4. MPV 시크 명령 실행 (여러 방법 시도)
                var seekSuccess = false;
                
                // 방법 1: 표준 시크 명령
                try {
                    mpvPlayer.command(["seek", targetPosition.toString(), "absolute", "exact"]);
                    seekSuccess = true;
                    console.log("VideoArea: Standard seek successful");
                } catch (e) {
                    console.log("Standard seek failed:", e);
                    
                    // 방법 2: 속성 직접 설정
                    try {
                        mpvPlayer.setProperty("time-pos", targetPosition);
                        seekSuccess = true;
                        console.log("VideoArea: Property seek successful");
                    } catch (e2) {
                        console.log("Property seek failed:", e2);
                        
                        // 방법 3: 키프레임 시크
                        try {
                            mpvPlayer.command(["seek", targetPosition.toString(), "absolute", "keyframes"]);
                            seekSuccess = true;
                            console.log("VideoArea: Keyframe seek successful");
                        } catch (e3) {
                            console.error("All seek methods failed:", e3);
                        }
                    }
                }
                
                // 5. UI 즉시 업데이트 (반응성)
                if (fps > 0) {
                    var calculatedFrame = Math.round(targetPosition * fps);
                    root.frame = calculatedFrame;
                    root.onFrameChangedEvent(calculatedFrame);
                }
                
                // 6. 메타데이터 업데이트 차단 해제 예약
                metadataBlockReleaseTimer.restart();
                
                return seekSuccess;
            } catch (e) {
                console.error("MPV seek error:", e);
                metadataUpdateBlocked = false;
                return false;
            }
        } else {
            console.error("Cannot seek: player not initialized");
            return false;
        }
    }
    
    // 특정 프레임으로 이동 - 시간 변환 후 seekToPosition 호출
    function seekToFrame(targetFrame) {
        if (mpvPlayer) {
            try {
                console.log("VideoArea: Frame-to-time seek request for frame:", targetFrame);
                
                // 1. 프레임 범위 검증
                if (targetFrame < 0) {
                    targetFrame = 0;
                }
                if (root.frames > 0 && targetFrame >= root.frames) {
                    targetFrame = root.frames - 1;
                }
                
                // 2. 프레임을 시간으로 변환
                if (fps <= 0) {
                    console.error("Invalid FPS - cannot convert frame to time");
                    return false;
                }
                
                var targetPosition = targetFrame / fps;
                
                // 3. 시간 기반 시크 실행 (단순화)
                return seekToPosition(targetPosition);
                
            } catch (e) {
                console.error("Frame seek error:", e);
                return false;
            }
        } else {
            console.error("Cannot seek: player not initialized");
            return false;
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
    
    // Keyboard focus - MPV 공식 권장 시간 기반 네비게이션
    focus: true
    Keys.onSpacePressed: playPause()
    Keys.onLeftPressed: {
        // 1프레임 뒤로 - seekToPosition 사용
        if (mpvPlayer && fps > 0) {
            var currentPos = mpvPlayer.getProperty("time-pos") || 0;
            var frameTime = 1.0 / fps;
            var targetPos = Math.max(0, currentPos - frameTime);
            
            seekToPosition(targetPos);
            console.log("Frame backward to:", targetPos);
        }
    }
    Keys.onRightPressed: {
        // 1프레임 앞으로 - seekToPosition 사용
        if (mpvPlayer && fps > 0) {
            var currentPos = mpvPlayer.getProperty("time-pos") || 0;
            var duration = mpvPlayer.getProperty("duration") || 0;
            var frameTime = 1.0 / fps;
            var targetPos = Math.min(duration - 0.1, currentPos + frameTime);
            
            seekToPosition(targetPos);
            console.log("Frame forward to:", targetPos);
        }
    }
    
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
