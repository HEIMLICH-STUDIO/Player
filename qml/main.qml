import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import Utils 1.0 as Utils

// Import local components
import ffmpeg 1.0
import "panels"  // 명시적으로 panels 디렉토리에서 VideoArea 가져오기
import "widgets" // widgets에서 ControlBar 사용하도록 변경
import "popups"
import "utils"

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 720
    minimumWidth: 640
    minimumHeight: 480
    title: qsTr("HYPER-PLAYER")
    color: Utils.ThemeManager.backgroundColor
    
    // Debugging - print loaded component information
    Component.onCompleted: {
        console.log("Main window loaded");
        console.log("Using VideoArea from:", (typeof VideoArea !== "undefined") ? "Available" : "Not available");
        console.log("FFmpeg support:", mpvSupported);
    }
    
    // Global properties
    property bool mpvSupported: hasFFmpegSupport
    property string currentMediaFile: ""
    property bool settingsPanelVisible: true
    property int currentFrame: 0
    property int totalFrames: 1000
    property real fps: 24.0
    property string currentTimecode: "00:00:00:00"
    property bool magnifierActive: false
    property bool scopesPanelVisible: false // legacy, kept for compatibility
    
    // Access theme properties from ThemeManager
    property alias themeManager: themeManagerAlias
    Utils.ThemeManager { id: themeManagerAlias }
    
    // Style constants - professional dark theme like DJV
    readonly property color accentColor: "#0078D7"  // Professional blue
    readonly property color secondaryColor: "#1DB954" // Green accent
    readonly property color textColor: "#FFFFFF"
    readonly property color panelColor: "#252525"
    readonly property color controlBgColor: "#1E1E1E"
    readonly property color darkControlColor: "#181818"
    readonly property color borderColor: "#333333"
    readonly property color sliderBgColor: "#333333"
    readonly property color toolButtonColor: "#2A2A2A"
    readonly property int panelWidth: 260
    
    // Font settings
    readonly property string mainFont: "Segoe UI"
    readonly property string monoFont: "Consolas"
    
    // Icon mapping to ensure proper display
    readonly property var iconMap: ({
        "play_arrow": "▶",
        "pause": "⏸",
        "skip_previous": "⏮",
        "skip_next": "⏭",
        "fast_rewind": "⏪",
        "fast_forward": "⏩",
        "chevron_left": "◀",
        "chevron_right": "▶",
        "folder_open": "📂",
        "settings": "⚙",
        "fullscreen": "⛶",
        "fullscreen_exit": "↙"
    })
    
    // Debug border display
    property bool showDebugBorders: false
    
    // Debug layout function
    function debugBorder(color) {
        if (showDebugBorders) {
            return Qt.createQmlObject(
                'import QtQuick; Rectangle { 
                    anchors.fill: parent; 
                    color: "transparent"; 
                    border.width: 1; 
                    border.color: "' + color + '"; 
                    z: 1000 
                }',
                parent
            );
        }
        return null;
    }
    
    // Frame information update function
    function updateFrameInfo() {
        if (videoArea && videoArea.mpvPlayer) {
            try {
                // Get current time position
                var pos = videoArea.mpvPlayer.getProperty("time-pos");
                if (pos !== undefined && pos !== null) {
                    // Update current frame
                    currentFrame = Math.round(pos * fps);
                
                    // Update timecode
                    var hours = Math.floor(pos / 3600);
                    var minutes = Math.floor((pos % 3600) / 60);
                    var seconds = Math.floor(pos % 60);
                    var frames = Math.round((pos % 1) * fps);
                    
                    currentTimecode = hours.toString().padStart(2, '0') + ":" +
                                    minutes.toString().padStart(2, '0') + ":" +
                                    seconds.toString().padStart(2, '0') + ":" +
                                    frames.toString().padStart(2, '0');
                }
                
                // Get duration
                var duration = videoArea.mpvPlayer.getProperty("duration");
                if (duration !== undefined && duration !== null) {
                    totalFrames = Math.ceil(duration * fps) - 1;
                }
                
            } catch (e) {
                console.error("Error updating frame info:", e);
            }
        }
    }
    
    // Main content layout
    Rectangle {
        id: mainContentArea
        anchors.fill: parent
        color: Utils.ThemeManager.backgroundColor
        
        // Debug border
        Rectangle {
            visible: showDebugBorders
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: "red"
            z: 100
        }
        
        // Video area and settings panel side by side
        SplitView {
            anchors.fill: parent
            orientation: Qt.Horizontal
            handle: Rectangle {
                implicitWidth: 1
                implicitHeight: parent.height
                color: Utils.ThemeManager.borderColor
            }
            
            // Video area
            Item {
                id: videoContainer
                SplitView.fillWidth: true
                SplitView.minimumWidth: 400
                
                // Debug border
                Rectangle {
                    visible: showDebugBorders
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: "green"
                    z: 100
                }
            
                // Video area component
                VideoArea {
                    id: videoArea
                    anchors.fill: parent
                
                    // Sync properties
                    currentMediaFile: root.currentMediaFile
                    currentFrame: root.currentFrame
                    totalFrames: root.totalFrames
                    fps: root.fps
                    currentTimecode: root.currentTimecode
                    
                    // Add event connections for seeking
                    onFrameChangedEvent: function(frame) {
                        // 중요: VideoArea에서 프레임 변경 시 메인 윈도우 업데이트
                        root.currentFrame = frame;
                        
                        // 컨트롤바에도 직접 알림 (양방향 동기화 보장)
                        if (controlBar && controlBar.currentFrame !== frame) {
                            controlBar.currentFrame = frame;
                        }
                    }
                    
                    onFpsChangedEvent: function(fps) {
                        root.fps = fps;
                    }
                    
                    onTotalFramesChangedEvent: function(frames) {
                        root.totalFrames = frames;
                    }
                }
            }
            
            // Settings panel
            Rectangle {
                id: settingsPanel
                color: Utils.ThemeManager.panelColor
                SplitView.preferredWidth: panelWidth
                visible: settingsPanelVisible
                
                // Debug border
                Rectangle {
                    visible: showDebugBorders
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: "blue"
                    z: 100
                }
                
                // Settings panel contents
                SettingsPanel {
                    anchors.fill: parent
                    mpvPlayer: videoArea.mpvPlayer
                    fps: root.fps
                }
            }
        }
        
        // Control bar at bottom
        ControlBar {
            id: controlBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            
            // Connect properties
            mpvObject: videoArea.mpvPlayer
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            isPlaying: videoArea.isPlaying
            mpvSupported: root.mpvSupported
            
            // Highlight when settings panel is open
            settingsPanelOpen: settingsPanelVisible
            
            // Connect signals
            onOpenFileRequested: videoArea.openFile()
            onPlayPauseRequested: videoArea.playPause()
            onToggleSettingsPanelRequested: {
                settingsPanelVisible = !settingsPanelVisible
            }
            onToggleFullscreenRequested: {
                if (root.visibility === Window.FullScreen) {
                    root.showNormal();
                } else {
                    root.showFullScreen();
                }
            }
            
            // Frame navigation handlers
            onFrameBackwardRequested: function(frames) {
                videoArea.stepBackward(frames);
            }
            
            onFrameForwardRequested: function(frames) {
                videoArea.stepForward(frames);
            }
            
            // Handle seek requests - 중요: 클릭 시크 처리를 위한 핵심 연결부
            onSeekToFrameRequested: function(frame) {
                console.log("Main: Timeline seek request -", frame);
                
                // 컨트롤바에서 시크 요청이 왔을 때 비디오 영역에 직접 전달
                if (videoArea) {
                    // VideoArea의 seekToFrame 함수 호출
                    videoArea.seekToFrame(frame);
                    
                    // 메인 윈도우 currentFrame도 즉시 업데이트 (UI 응답성)
                    root.currentFrame = frame;
                }
            }
        }
    }
    
    // Magnifier overlay
    MagnifierOverlay {
        id: magnifier
        anchors.fill: mainContentArea
        visible: magnifierActive && videoArea.mpvPlayer && videoArea.mpvPlayer.hasVideo
        mpvObject: videoArea.mpvPlayer
        z: 10 // Above video but below dialogs
    }
    
    // Keyboard shortcuts
    Shortcut {
        sequence: "Space"
        onActivated: {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.pause = !videoArea.mpvPlayer.pause;
            }
        }
    }
    
    Shortcut {
        sequence: "Left"
        onActivated: {
            if (videoArea.mpvPlayer) {
                var newFrame = Math.max(0, currentFrame - 1);
                var pos = newFrame / fps;
                videoArea.mpvPlayer.seekToPosition(pos);
            }
        }
    }
    
    Shortcut {
        sequence: "Right"
        onActivated: {
            if (videoArea.mpvPlayer) {
                var newFrame = Math.min(totalFrames - 1, currentFrame + 1);
                var pos = newFrame / fps;
                videoArea.mpvPlayer.seekToPosition(pos);
            }
        }
    }
    
    Shortcut {
        sequence: "Ctrl+Left"
        onActivated: {
            if (videoArea.mpvPlayer) {
                var newFrame = Math.max(0, currentFrame - 10);
                var pos = newFrame / fps;
                videoArea.mpvPlayer.seekToPosition(pos);
            }
        }
    }
    
    Shortcut {
        sequence: "Ctrl+Right"
        onActivated: {
            if (videoArea.mpvPlayer) {
                var newFrame = Math.min(totalFrames - 1, currentFrame + 10);
                var pos = newFrame / fps;
                videoArea.mpvPlayer.seekToPosition(pos);
            }
        }
    }
    
    Shortcut {
        sequence: "Home"
        onActivated: {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.setProperty("time-pos", 0);
            }
        }
    }
    
    Shortcut {
        sequence: "End"
        onActivated: {
            if (videoArea.mpvPlayer && videoArea.mpvPlayer.duration) {
                videoArea.mpvPlayer.setProperty("time-pos", videoArea.mpvPlayer.duration - (1/fps));
            }
        }
    }
    
    Shortcut {
        sequence: "F"
        onActivated: {
            if (root.visibility === Window.FullScreen) {
                root.showNormal();
            } else {
                root.showFullScreen();
            }
        }
    }
    
    Shortcut {
        sequence: "M"
        onActivated: magnifierActive = !magnifierActive
    }
    
    Shortcut {
        sequence: "T"
        onActivated: themeManager.toggleTheme()
    }
} 

