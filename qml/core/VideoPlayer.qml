import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 중요: UI VideoArea만 사용하도록 수정
import "../ui"
import "../utils"
import "../widgets"

// Main video player component
Item {
    id: root

    // 핵심 상태를 이곳에서 통합 관리
    property int currentFrame: 0
    property int totalFrames: 0
    property real fps: 24.0
    property string currentFile: ""
    
    // Video metadata properties
    property string videoCodec: ""
    property string videoFormat: ""
    property string videoResolution: ""
    property string videoBitrate: ""
    property real videoAspectRatio: 1.0
    property string videoColorSpace: ""
    property string creationDate: ""

    // Internal state properties
    property alias videoArea: videoArea
    property alias statusBar: statusBar
    property bool isFullscreen: false
    property bool isPlaying: videoArea ? videoArea.isPlaying : false
    
    // 프레임 변경 시 감지하여 전체 동기화 처리
    onCurrentFrameChanged: {
        // 현재 프레임 변경 시 로그 출력
        // console.log("VideoPlayer: Current frame changed to ->", currentFrame);
        
        // 관련 객체들 강제 동기화
        if (controlBar && controlBar.frameTimeline) {
            // 타임라인에 강제 업데이트가 필요한 경우 확인
            if (controlBar.frameTimeline.currentFrame !== currentFrame && 
                !controlBar.frameTimeline.isDragging) {
                // console.log("VideoPlayer: Force updating timeline frame");
                controlBar.frameTimeline.currentFrame = currentFrame;
            }
        }
    }
    
    // mpvObject를 캐싱하여 불필요한 변경 감지 방지
    property var _cachedMpvObject: null
    
    // Function to safely access the mpv object
    function getMpvObject() {
        if (!videoArea) {
            console.error("VideoPlayer: videoArea is null");
            return null;
        }
        
        if (!videoArea.mpvSupported) {
            console.error("VideoPlayer: mpvSupported is false");
            return null;
        }
        
        // 직접 mpvPlayer 속성 접근 (VideoArea에서 추가된 새 속성)
        var player = videoArea.mpvPlayer;
        if (!player) {
            console.error("VideoPlayer: mpvPlayer is null");
            return null;
        }
        
        // MPV 객체가 변경되었는지 확인
        if (player !== _cachedMpvObject) {
            console.log("VideoPlayer: New mpvPlayer object detected");
            _cachedMpvObject = player;
            
            // ControlBar에 새로운 MPV 객체 전달 (지연 후)
            Qt.callLater(function() {
                if (controlBar) {
                    console.log("VideoPlayer: Passing new MPV object to ControlBar");
                    controlBar.mpvObject = player;
                    
                    // 메타데이터 새로고침 요청
                    Qt.callLater(function() {
                        if (controlBar.refreshMetadataForNewFile) {
                            controlBar.refreshMetadataForNewFile();
                        }
                    });
                }
            });
        }
        
        return player;
    }

    // 강화된 동기화 처리 - 동기화 중재자 역할
    Connections {
        target: videoArea
        
        // 비디오 영역에서 프레임 변경될 때 호출
        function onOnFrameChangedEvent(frame) {
            // console.log("MPV Sync: Frame change detected from video area:", frame);

            // 타임라인이 드래그 중이면 영상 측 업데이트를 잠시 무시하여
            // 사용자가 선택한 프레임을 우선시한다. 드래그 중인 프레임은
            // ControlBar에서 VideoArea로 직접 전달되므로 여기서는 무시한다.
            if (controlBar && controlBar.frameTimeline &&
                controlBar.frameTimeline.isDragging) {
                // console.log("Timeline is dragging - ignoring MPV sync event");
                return;
            }
            
            // 드래그 완료 직후 안정화 기간 동안도 MPV 싱크 이벤트 무시
            if (controlBar && controlBar.frameTimeline &&
                (controlBar.frameTimeline.recentlyDragged || controlBar.frameTimeline.seekStabilizing)) {
                // console.log("Timeline in stabilization period - ignoring MPV sync event");
                return;
            }

            root.currentFrame = frame;
            
            // MPV 현재 위치 확인
            var mpv = getMpvObject();
            if (mpv) {
                var mpvPos = mpv.getProperty("time-pos");
                var mpvFrame = Math.round(mpvPos * fps);
                
                // 불일치 확인 및 강제 동기화
                if (Math.abs(mpvFrame - frame) > 1) {
                    console.log("MPV Sync: Mismatch detected - MPV:", mpvFrame, "UI:", frame);
                    var pos = frame / fps;
                    mpv.setProperty("time-pos", pos);
                }
            }
        }
        
        function onOnTotalFramesChangedEvent(frames) {
            root.totalFrames = frames;
        }
        
        function onOnFileChangedEvent(filename) {
            root.currentFile = filename;
        }
        
        function onOnFpsChangedEvent(fpsValue) {
            root.fps = fpsValue;
        }
        
        function onMetadataChanged() {
            // Update video metadata properties
            root.videoCodec = videoArea.videoCodec;
            root.videoFormat = videoArea.videoFormat;
            root.videoResolution = videoArea.videoResolution;
            root.videoBitrate = videoArea.videoBitrate;
            root.videoAspectRatio = videoArea.videoAspectRatio;
            root.videoColorSpace = videoArea.videoColorSpace;
            root.creationDate = videoArea.creationDate;
            
            console.log("VideoPlayer: Metadata updated from VideoArea");
            console.log("- Codec:", root.videoCodec);
            console.log("- Format:", root.videoFormat);
            console.log("- Resolution:", root.videoResolution);
            console.log("- Creation date:", root.creationDate);
        }
    }
    
    // 동기화 중재 타이머
    Timer {
        id: syncMediatorTimer
        interval: 2000  // 2초 간격으로 늘림 (CPU 부하 감소)
        repeat: true
        running: true   // 기본적으로 항상 실행 (앱 실행 필수)
        
        onTriggered: {
            // MPV 플레이어와 UI 상태 동기화 확인
            var mpv = getMpvObject();
            if (mpv) {
                try {
                    var timePos = mpv.getProperty("time-pos");
                    if (timePos !== undefined && timePos !== null) {
                        var mpvFrame = Math.round(timePos * fps);
                        
                        // 드래그 중이거나 안정화 기간에는 동기화 건너뛰기
                        if (controlBar && controlBar.frameTimeline && 
                            (controlBar.frameTimeline.isDragging || 
                             controlBar.frameTimeline.seekStabilizing || 
                             controlBar.frameTimeline.recentlyDragged)) {
                            return;
                        }
                        
                        // 큰 차이가 있을 때만 동기화 (CPU 부하 감소)
                        if (Math.abs(mpvFrame - currentFrame) > 5) {  // 더 높은 차이 값 설정
                            console.log("Sync mediator: Frame mismatch correction - MPV:", mpvFrame, "UI:", currentFrame);
                            root.currentFrame = mpvFrame;
                        }
                    }
                } catch (e) {
                    console.error("Sync mediator error:", e);
                }
            }
        }
    }
    
    // Metadata refresh timer - 파일 로드 직후 한 번만 실행됨
    Timer {
        id: metadataRefreshTimer
        interval: 1000  // 1초 후 한 번만 실행
        repeat: false   // 반복하지 않음
        running: false  // 타이머 비활성화 - 수동으로 시작
        
        onTriggered: {
            // 새 파일이 로드될 때만 메타데이터 갱신
            if (currentFile && videoArea && videoArea.mpvPlayer) {
                console.log("VideoPlayer: Attempting to load metadata from timer:", currentFile);
                
                if (!videoArea.metadataLoaded) {
                    videoArea.fetchVideoMetadata();
                    console.log("VideoPlayer: Metadata fetch called (from timer)");
                    // 중복 로드 방지
                    videoArea.metadataLoaded = true;
                } else {
                    console.log("VideoPlayer: Metadata already loaded, skipping timer fetch");
                }
            }
        }
    }
    
    // 새 파일이 로드될 때 메타데이터 즉시 가져오기
    Connections {
        target: root
        function onCurrentFileChanged() {
            if (currentFile && videoArea && videoArea.mpvPlayer) {
                console.log("VideoPlayer: File change detected, preparing to load metadata:", currentFile);
                
                // 메타데이터 강제 초기화 (핵심 부분)
                videoArea.metadataLoaded = false;
                
                // 즉시 메타데이터 가져오기 시도
                videoArea.fetchVideoMetadata();
                
                // 백업으로 타이머도 시작
                console.log("VideoPlayer: Scheduling metadata load with timer (backup)");
                metadataRefreshTimer.restart();
                
                // 파일 로드 직후 컨트롤바에 메타데이터 새로고침 요청
                if (controlBar && typeof controlBar.refreshMetadataForNewFile === "function") {
                    console.log("VideoPlayer: Requesting metadata refresh to ControlBar");
                    // 즉시 요청과 지연 요청 모두 실행
                    controlBar.refreshMetadataForNewFile();
                    
                    // 약간 지연된 후에도 한 번 더 시도
                    Qt.callLater(function() {
                        videoArea.metadataLoaded = false;  // 강제 초기화
                        controlBar.refreshMetadataForNewFile();
                    });
                }
            }
        }
    }
    
    // Settings window
    SettingsPanel {
        id: settingsWindow
        visible: false
        mpvObject: getMpvObject()
    }
    
    // Scopes window
    ScopeWindow {
        id: scopeWindow
        visible: false
        videoArea: videoArea
        
        Component.onCompleted: {
            console.log("ScopeWindow initialized");
        }
    }
    
    // Main layout - separates video area and control area
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        // Video screen area (set to expand in the layout)
        VideoArea {
            id: videoArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Connect the settingsToggleRequested signal - commented out until fixed
            // onSettingsToggleRequested: {
            //     // Forward to the settings toggle handler
            //     settingsWindow.visible = !settingsWindow.visible
            // }
            
            // 프레임/파일 변경 이벤트에서 상태 갱신
            // 이제 Connections 객체에서 처리
            
            // 추가: 컴포넌트 생성 후 강제 MPV 검증
            Component.onCompleted: {
                // videoArea 초기화 직후 MPV 객체 검증
                Qt.callLater(function() {
                    var mpv = getMpvObject();
                    if (mpv) {
                        console.log("VideoArea MPV object initialized correctly");
                    } else {
                        console.error("VideoArea MPV object initialization failed!");
                    }
                });
            }
        }

        // Timeline/control bar
        ControlBar {
            id: controlBar
            Layout.fillWidth: true
            isPlaying: root.isPlaying
            currentFrame: root.currentFrame  // 양방향 동기화를 위한 핵심 바인딩
            totalFrames: root.totalFrames
            fps: root.fps
            
            // Pass metadata to control bar
            videoCodec: root.videoCodec
            videoFormat: root.videoFormat
            videoResolution: root.videoResolution
            videoBitrate: root.videoBitrate
            
            // 중요: MPV 객체 직접 연결 - 좀 더 안전하게 구현
            mpvObject: getMpvObject()
            
            // MPV 객체 연결 상태 확인 및 강제 초기화
            Component.onCompleted: {
                console.log("ControlBar initialized, MPV object connection confirmed");
                
                // MPV 객체 연결 및 메타데이터 로드 상태 확인
                Qt.callLater(function() {
                    if (mpvObject) {
                        console.log("ControlBar: MPV object connected");
                        
                        // 메타데이터 강제 초기화
                        refreshMetadataForNewFile();
                    } else {
                        console.error("ControlBar: MPV object connection failed");
                        
                        // 지연 후 다시 연결 시도
                        Qt.callLater(function() {
                            mpvObject = getMpvObject();
                            if (mpvObject) {
                                console.log("ControlBar: MPV object reconnected successfully");
                                refreshMetadataForNewFile();
                            }
                        });
                    }
                });
            }
            
            // 시그널 연결
            onSeekToFrameRequested: function(frame) {
                console.log("VideoPlayer: Seek frame request -", frame);
                
                // 1. First, update internal state immediately
                root.currentFrame = frame;
                
                // 2. Pass seek command to video area
                videoArea.seekToFrame(frame);
                
                // 3. Pass seek command directly to MPV (double guarantee)
                var mpv = getMpvObject();
                if (mpv) {
                    var pos = frame / fps;
                    mpv.setProperty("time-pos", pos);
                    console.log("MPV direct seek command:", pos);
                }
            }
            
            onOpenFileRequested: videoArea.openFile()
            onPlayPauseRequested: videoArea.playPause()
            onFrameBackRequested: function(frames) { videoArea.stepBackward(frames) }
            onFrameForwardRequested: function(frames) { videoArea.stepForward(frames) }
            onFullscreenToggleRequested: {
                isFullscreen = !isFullscreen
                toggleFullscreen()
            }
            onSettingsToggleRequested: {
                // Open settings window instead
                if (!settingsWindow.visible) {
                    settingsWindow.show()
                }
            }
            onToggleScopesRequested: {
                // Open/close scopes window
                if (!scopeWindow.visible) {
                    console.log("Showing scope window");
                    scopeWindow.show();
                } else {
                    scopeWindow.hide();
                }
            }
        }
        
        // Expose controlBar through alias property
        property alias controlBar: controlBar

        // Status bar
        StatusBar {
            id: statusBar
            Layout.fillWidth: true
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            currentFile: root.currentFile
            mpvObject: getMpvObject()  // mpv 객체 참조 전달
        }
    }
    
    // Fullscreen toggle function
    function toggleFullscreen() {
        // This function needs to be implemented in C++ code
        console.log("Fullscreen toggled:", isFullscreen)
    }
    
    // Functions to be called from outside
    function loadFile(path) {
        if (videoArea) {
            videoArea.loadFile(path)
        }
    }
    
    Component.onCompleted: {
        console.log("VideoPlayer initialized")
        
        // Connect isPlaying property to videoArea after components are initialized
        isPlaying = Qt.binding(function() { return videoArea.isPlaying; })
    }
}