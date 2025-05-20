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
    
    // Internal reference properties
    property alias videoArea: videoArea
    property alias controlBar: controlBar
    property alias statusBar: statusBar
    property bool isFullscreen: false
    
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
            
            // Video-related event handling
            onOnFrameChangedEvent: function(frame) {
                controlBar.currentFrame = frame
                statusBar.currentFrame = frame
            }
            
            onOnTotalFramesChangedEvent: function(frames) {
                controlBar.totalFrames = frames
                statusBar.totalFrames = frames
            }
            
            onOnFileChangedEvent: function(filename) {
                statusBar.currentFile = filename
            }
            
            onOnFpsChangedEvent: function(fps) {
                controlBar.fps = fps
                statusBar.fps = fps
            }
        }
        
        // Timeline/control bar
        ControlBar {
            id: controlBar
            Layout.fillWidth: true
            isPlaying: videoArea.isPlaying
            
            // Control button event handling
            onOpenFileRequested: videoArea.openFile()
            onPlayPauseRequested: videoArea.playPause()
            onFrameBackRequested: function(frames) { videoArea.stepBackward(frames) }
            onFrameForwardRequested: function(frames) { videoArea.stepForward(frames) }
            onSeekToFrameRequested: function(frame) {
                videoArea.seekToFrame(frame)
            }
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