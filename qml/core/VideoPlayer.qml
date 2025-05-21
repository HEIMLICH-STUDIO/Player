import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Import components from relative paths
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
    
    // Function to safely access the mpv object
    function getMpvObject() {
        if (!videoArea) {
            console.log("VideoPlayer: videoArea is null");
            return null;
        }
        
        if (!videoArea.mpvSupported) {
            console.log("VideoPlayer: mpvSupported is false");
            return null;
        }
        
        // Explicitly check if mpvLoader exists
        var loader = videoArea.mpvLoader;
        if (!loader) {
            console.log("VideoPlayer: mpvLoader is null");
            return null;
        }
        
        // Explicitly check if loader.item exists
        var item = loader.item;
        if (!item) {
            console.log("VideoPlayer: mpvLoader.item is null");
            return null;
        }
        
        // Check if mpvPlayer exists
        var player = item.mpvPlayer;
        if (!player) {
            console.log("VideoPlayer: mpvPlayer is null");
            return null;
        }
        
        console.log("VideoPlayer: mpvPlayer found");
        return player;
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
            onOnFrameChangedEvent: function(frame) {
                root.currentFrame = frame
            }
            onOnTotalFramesChangedEvent: function(frames) {
                root.totalFrames = frames
            }
            onOnFileChangedEvent: function(filename) {
                root.currentFile = filename
            }
            onOnFpsChangedEvent: function(fpsValue) {
                root.fps = fpsValue
            }
        }

        // Timeline/control bar
        ControlBar {
            id: controlBar
            Layout.fillWidth: true
            isPlaying: root.isPlaying
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            // 시그널 연결
            onSeekToFrameRequested: function(frame) {
                videoArea.seekToFrame(frame)
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