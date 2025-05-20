import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import Utils 1.0 as Utils

// Import local components
import mpv 1.0
import "panels"
import "controls"
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
    
    // Global properties
    property bool mpvSupported: hasMpvSupport
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
    
    // Main content layout
    Rectangle {
        id: mainContentArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusBar.top
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
    }
    
    // Status bar
    StatusBar {
        id: statusBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomControlBar.top
        height: 24  // Fixed height
        visible: true  // Always visible
        
        currentMediaFile: root.currentMediaFile
        currentFrame: root.currentFrame
        totalFrames: root.totalFrames
        
        // Debug border
        Rectangle {
            visible: showDebugBorders
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: "magenta"
            z: 100
        }
    }
    
    // Bottom control bar
    ControlBar {
        id: bottomControlBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 130  // Increased height to include timeline (90+40)
        
        // Property connections
        mpvObject: videoArea.mpvPlayer
        currentFrame: root.currentFrame
        totalFrames: root.totalFrames
        fps: root.fps
        mpvSupported: root.mpvSupported
        
        // Debug border
        Rectangle {
            visible: showDebugBorders
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: "yellow"
            z: 100
        }
        
        // Timeline bar in control bar's timeline area
        FrameTimelineBar {
            id: timelineBar
            anchors.fill: parent.children[0]  // Fit to timeline area
            visible: true  // Always visible
            
            mpvObject: videoArea.mpvPlayer
            
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            isPlaying: videoArea.mpvPlayer ? videoArea.mpvPlayer.isPlaying : false
            
            // Debug border
            Rectangle {
                visible: showDebugBorders
                anchors.fill: parent
                color: "transparent"
                border.width: 2
                border.color: "cyan"
                z: 100
            }
        }
        
        // Connect control bar signals
        onOpenFileRequested: {
            videoArea.openFile()
        }
        
        onToggleSettingsPanelRequested: {
            settingsPanelVisible = !settingsPanelVisible
        }
        
        onTakeScreenshotRequested: {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.screenshot()
            }
        }
        
        onToggleFullscreenRequested: {
            if (root.visibility === Window.FullScreen) {
                root.showNormal()
            } else {
                root.showFullScreen()
            }
        }
        
        onToggleScopesRequested: {
            videoArea.toggleScopes()
        }
        
        onFrameBackwardRequested: function(frames) {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.frameStep(-frames)
            }
        }
        
        onFrameForwardRequested: function(frames) {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.frameStep(frames)
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
                videoArea.mpvPlayer.playPause()
            }
        }
    }
    
    Shortcut {
        sequence: "Left"
        onActivated: bottomControlBar.frameBackwardRequested(1)
    }
    
    Shortcut {
        sequence: "Right"
        onActivated: bottomControlBar.frameForwardRequested(1)
    }
    
    Shortcut {
        sequence: "Ctrl+Left"
        onActivated: bottomControlBar.frameBackwardRequested(10)
    }
    
    Shortcut {
        sequence: "Ctrl+Right"
        onActivated: bottomControlBar.frameForwardRequested(10)
    }
    
    Shortcut {
        sequence: "Home"
        onActivated: {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.setProperty("time-pos", 0)
            }
        }
    }
    
    Shortcut {
        sequence: "End"
        onActivated: {
            if (videoArea.mpvPlayer && videoArea.mpvPlayer.duration) {
                videoArea.mpvPlayer.setProperty("time-pos", videoArea.mpvPlayer.duration - (1/fps))
            }
        }
    }
    
    Shortcut {
        sequence: "F"
        onActivated: bottomControlBar.toggleFullscreenRequested()
    }
    
    Shortcut {
        sequence: "S"
        onActivated: bottomControlBar.takeScreenshotRequested()
    }
    
    Shortcut {
        sequence: "M"
        onActivated: magnifierActive = !magnifierActive
    }
    
    Shortcut {
        sequence: "Ctrl+S"
        onActivated: bottomControlBar.toggleScopesRequested()
    }
    
    Shortcut {
        sequence: "T"
        onActivated: themeManager.toggleTheme()
    }
} 
