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
    
    // Timer for delayed second seek
    Timer {
        id: delayedSeekTimer
        interval: 150
        repeat: false
        property int targetFrame: 0
        
        onTriggered: {
            if (mpvObject) {
                var player = getMpvPlayer();
                if (player) {
                    // 5.1 Command for more precise position
                    var timePos = targetFrame / fps;
                    player.command(["seek", timePos.toString(), "absolute", "exact"]);
                    
                    // 5.2 Maintain paused state (when in pause mode)
                    if (!isPlaying) {
                        player.setProperty("pause", true);
                    }
                    
                    // 5.3 Recheck current frame status and emit signal
                    var actualPos = player.getProperty("time-pos");
                    if (actualPos !== undefined && actualPos !== null) {
                        var actualFrame = Math.round(actualPos * fps);
                        if (Math.abs(actualFrame - targetFrame) > 1) {
                            console.log("Frame mismatch detected:", actualFrame, "vs", targetFrame);
                            frame = actualFrame;
                            onFrameChangedEvent(actualFrame);
                        }
                    }
                }
            }
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
    
    // 특정 프레임으로 이동
    function seekToFrame(targetFrame) {
        var player = getMpvPlayer();
        if (player) {
            try {
                console.log("직접 시크 요청 - 프레임:", targetFrame);
                
                // 1. 일시 정지 상태 확인 (프레임 정확도 위해)
                if (!isPlaying) {
                    player.setProperty("pause", true);
                }
                
                // 2. 프레임을 시간으로 변환 (초 단위)
                var timePos = targetFrame / fps;
                
                // 3. 여러 방식으로 시크 명령 전송 (강력한 동기화 위해)
                // 3.1 MPV 속성 바로 설정 (가장 빠름)
                player.setProperty("time-pos", timePos);
                
                // 3.2 명령어로 정확한 시크 수행 (더 정확함)
                player.command(["seek", timePos.toString(), "absolute", "exact"]);
                
                // 4. UI 업데이트
                frame = targetFrame;
                onFrameChangedEvent(targetFrame);
                
                // 5. 안정적인 동기화를 위해 약간 지연된 두 번째 시크 수행
                delayedSeekTimer.targetFrame = targetFrame;
                delayedSeekTimer.restart();
            } catch (e) {
                console.error("Error seeking to frame:", e);
                showMessage("Error seeking to frame: " + e);
            }
        } else {
            showMessage("Player not initialized");
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
