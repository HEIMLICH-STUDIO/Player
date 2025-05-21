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

    // Internal reference properties
    property alias videoArea: videoArea
    property alias controlBar: controlBar
    property alias statusBar: statusBar
    property bool isFullscreen: false
    property bool isPlaying: videoArea.isPlaying
    
    // 프레임 변경 시 감지하여 전체 동기화 처리
    onCurrentFrameChanged: {
        // 현재 프레임 변경 시 로그 출력
        console.log("VideoPlayer: 현재 프레임 변경됨 ->", currentFrame);
        
        // 관련 객체들 강제 동기화
        if (controlBar && controlBar.frameTimeline) {
            // 타임라인에 강제 업데이트가 필요한 경우 확인
            if (controlBar.frameTimeline.currentFrame !== currentFrame && 
                !controlBar.frameTimeline.isDragging) {
                console.log("VideoPlayer: 타임라인 프레임 강제 업데이트");
                controlBar.frameTimeline.currentFrame = currentFrame;
            }
        }
    }
    
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
        
        // Explicitly check if mpvLoader exists
        var loader = videoArea.mpvLoader;
        if (!loader) {
            console.error("VideoPlayer: mpvLoader is null");
            return null;
        }
        
        // Explicitly check if loader.item exists
        var item = loader.item;
        if (!item) {
            console.error("VideoPlayer: mpvLoader.item is null");
            return null;
        }
        
        // Check if mpvPlayer exists
        var player = item.mpvPlayer;
        if (!player) {
            console.error("VideoPlayer: mpvPlayer is null");
            return null;
        }
        
        console.log("VideoPlayer: mpvPlayer found");
        return player;
    }

    // 강화된 동기화 처리 - 동기화 중재자 역할
    Connections {
        target: videoArea
        
        // 비디오 영역에서 프레임 변경될 때 호출
        function onOnFrameChangedEvent(frame) {
            console.log("MPV 싱크: 비디오에서 프레임 변경 감지:", frame);
            root.currentFrame = frame;
            
            // MPV 현재 위치 확인
            var mpv = getMpvObject();
            if (mpv) {
                var mpvPos = mpv.getProperty("time-pos");
                var mpvFrame = Math.round(mpvPos * fps);
                
                // 불일치 확인 및 강제 동기화
                if (Math.abs(mpvFrame - frame) > 1) {
                    console.log("MPV 싱크: 불일치 발견 - MPV:", mpvFrame, "UI:", frame);
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
    }
    
    // 동기화 중재 타이머
    Timer {
        id: syncMediatorTimer
        interval: 500  // 0.5초마다 완전한 동기화 상태 확인
        repeat: true
        running: true
        
        onTriggered: {
            // MPV 플레이어와 UI 상태 동기화 확인
            var mpv = getMpvObject();
            if (mpv) {
                try {
                    var timePos = mpv.getProperty("time-pos");
                    if (timePos !== undefined && timePos !== null) {
                        var mpvFrame = Math.round(timePos * fps);
                        
                        // UI와 MPV 사이 큰 차이가 있는지 확인
                        if (Math.abs(mpvFrame - currentFrame) > 2) {
                            console.log("싱크 중재자: 프레임 불일치 수정 - MPV:", mpvFrame, "UI:", currentFrame);
                            
                            // 1. MPV 상태가 우선 - UI 업데이트
                            if (!controlBar.frameTimeline.isDragging) {
                                root.currentFrame = mpvFrame;
                            }
                            // 2. 드래그 중이면 MPV 업데이트
                            else {
                                var pos = currentFrame / fps;
                                mpv.setProperty("time-pos", pos);
                            }
                        }
                    }
                } catch (e) {
                    console.error("동기화 중재자 오류:", e);
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

            // 프레임/파일 변경 이벤트에서 상태 갱신
            // 이제 Connections 객체에서 처리
            
            // 추가: 컴포넌트 생성 후 강제 MPV 검증
            Component.onCompleted: {
                // videoArea 초기화 직후 MPV 객체 검증
                Qt.callLater(function() {
                    var mpv = getMpvObject();
                    if (mpv) {
                        console.log("VideoArea MPV 객체 정상 초기화됨");
                    } else {
                        console.error("VideoArea MPV 객체 초기화 실패!");
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
            
            // 중요: MPV 객체 직접 연결 - 좀 더 안전하게 구현
            mpvObject: {
                var mpv = getMpvObject();
                if (mpv) {
                    console.log("VideoPlayer: MPV 객체를 ControlBar에 전달");
                    return mpv;
                } else {
                    console.error("VideoPlayer: 유효한 MPV 객체가 없음");
                    return null;
                }
            }
            
            // 시그널 연결
            onSeekToFrameRequested: function(frame) {
                console.log("VideoPlayer: 프레임 시크 요청 -", frame);
                
                // 1. 먼저 내부 상태 업데이트로 UI 즉시 반응
                root.currentFrame = frame;
                
                // 2. 비디오 영역에 시크 명령 전달
                videoArea.seekToFrame(frame);
                
                // 3. MPV에 직접 시크 명령 전달 (더블 보장)
                var mpv = getMpvObject();
                if (mpv) {
                    var pos = frame / fps;
                    mpv.setProperty("time-pos", pos);
                    console.log("MPV 직접 시크 명령:", pos);
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

        // Status bar
        StatusBar {
            id: statusBar
            Layout.fillWidth: true
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            currentFile: root.currentFile
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
    }
}