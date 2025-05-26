import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../utils"

Window {
    id: root
    title: qsTr("Scopes")
    width: 640
    height: 360
    color: ThemeManager.dialogColor
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
    visible: false

    // Reference to main video player
    property var videoArea: null
    property string currentFile: ""
    
    // Timers for filter application
    Timer {
        id: histogramTimer
        interval: 500
        repeat: false
        property var targetMpv: null
        onTriggered: {
            if (targetMpv) {
                try {
                    targetMpv.command(["vf", "set", "lavfi=histogram"]);
                    console.log("Histogram filter applied");
                } catch (e) {
                    console.error("Failed to apply histogram filter:", e);
                }
            }
        }
    }
    
    Timer {
        id: vectorscopeTimer
        interval: 500
        repeat: false
        property var targetMpv: null
        onTriggered: {
            if (targetMpv) {
                try {
                    targetMpv.command(["vf", "set", "lavfi=vectorscope"]);
                    console.log("Vectorscope filter applied");
                } catch (e) {
                    console.error("Failed to apply vectorscope filter:", e);
                }
            }
        }
    }
    
    // Update scopes whenever the main video file changes
    onVideoAreaChanged: {
        if (videoArea) {
            // Detect video filename changes
            videoArea.onOnFileChangedEvent.connect(function(filename) {
                if (filename !== "") {
                    currentFile = filename;
                    updateScopes();
                }
            });
        }
    }
    
    onVisibleChanged: {
        if (visible && currentFile !== "") {
            updateScopes();
        }
    }

    // Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Scope controls area
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: ThemeManager.tabBarColor
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15

                CheckBox {
                    id: histogramCheck
                    text: "Histogram"
                    checked: true
                    
                    contentItem: Text {
                        text: parent.text
                        color: ThemeManager.textColor
                        font.pixelSize: 14
                        leftPadding: histogramCheck.indicator.width + 6
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onCheckedChanged: {
                        // Show/hide histogram view
                        if (scopeLoader.item && scopeLoader.item.histogramView) {
                            scopeLoader.item.histogramView.visible = histogramCheck.checked;
                            updateScopes();
                        }
                    }
                }

                CheckBox {
                    id: vectorscopeCheck
                    text: "Vectorscope"
                    checked: true
                    
                    contentItem: Text {
                        text: parent.text
                        color: ThemeManager.textColor
                        font.pixelSize: 14
                        leftPadding: vectorscopeCheck.indicator.width + 6
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onCheckedChanged: {
                        // Show/hide vectorscope view
                        if (scopeLoader.item && scopeLoader.item.vectorscopeView) {
                            scopeLoader.item.vectorscopeView.visible = vectorscopeCheck.checked;
                            updateScopes();
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Status text
                Text {
                    id: statusText
                    color: ThemeManager.textColor
                    font.pixelSize: 12
                    text: "Please load a video first"
                    visible: currentFile === ""
                }
            }
        }
        
        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: ThemeManager.borderColor
        }
        
        // Scopes area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#121212"
            
            // MPV scope loader
            Loader {
                id: scopeLoader
                anchors.fill: parent
                active: true
                
                sourceComponent: Item {
                    id: scopeContainer
                    
                    // Properties to access histogram and vectorscope views from outside
                    property alias histogramView: histogramView
                    property alias vectorscopeView: vectorscopeView
                    property alias histogramMpvLoader: histogramMpvLoader
                    property alias vectorscopeMpvLoader: vectorscopeMpvLoader
                    
                    // Histogram view
                    Rectangle {
                        id: histogramView
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: parent.width / 2
                        height: parent.height
                        color: "#121212"
                        visible: histogramCheck.checked
                        
                        // Histogram FFmpeg instance
                        Loader {
                            id: histogramMpvLoader
                            anchors.fill: parent
                            anchors.margins: 10
                            active: typeof hasFFmpegSupport !== "undefined" ? hasFFmpegSupport : false
                            
                            sourceComponent: Component {
                                Item {
                                    property var mpvPlayer: null
                                    
                                    Component.onCompleted: {
                                        try {
                                            // Create MPV instance
                                            var component = Qt.createQmlObject(
                                                'import ffmpeg 1.0; FFmpegObject { anchors.fill: parent }',
                                                this,
                                                "histogram_ffmpeg"
                                            );
                                            
                                            if (component) {
                                                mpvPlayer = component;
                                                console.log("Histogram MPV created");
                                            }
                                        } catch (e) {
                                            console.error("Failed to create Histogram MPV:", e);
                                        }
                                    }
                                }
                            }
                        }
                        
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 10
                            text: "Histogram"
                            color: "white"
                            font.pixelSize: 14
                            z: 1
                        }
                    }
                    
                    // Vectorscope view
                    Rectangle {
                        id: vectorscopeView
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: parent.width / 2
                        height: parent.height
                        color: "#121212"
                        visible: vectorscopeCheck.checked
                        
                        // Vectorscope FFmpeg instance
                        Loader {
                            id: vectorscopeMpvLoader
                            anchors.fill: parent
                            anchors.margins: 10
                            active: typeof hasFFmpegSupport !== "undefined" ? hasFFmpegSupport : false
                            
                            sourceComponent: Component {
                                Item {
                                    property var mpvPlayer: null
                                    
                                    Component.onCompleted: {
                                        try {
                                            // Create MPV instance
                                            var component = Qt.createQmlObject(
                                                'import ffmpeg 1.0; FFmpegObject { anchors.fill: parent }',
                                                this,
                                                "vectorscope_ffmpeg"
                                            );
                                            
                                            if (component) {
                                                mpvPlayer = component;
                                                console.log("Vectorscope MPV created");
                                            }
                                        } catch (e) {
                                            console.error("Failed to create Vectorscope MPV:", e);
                                        }
                                    }
                                }
                            }
                        }
                        
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 10
                            text: "Vectorscope"
                            color: "white"
                            font.pixelSize: 14
                            z: 1
                        }
                    }
                }
            }
        }
    }
    
    // Update scopes function
    function updateScopes() {
        if (!videoArea || !videoArea.ffmpegSupported || currentFile === "") {
            statusText.text = "No video loaded";
            return;
        }
        
        if (!scopeLoader.item) {
            console.log("Scope loader item is null");
            return;
        }
        
        statusText.text = "";
        
        try {
            // Update histogram
            if (histogramCheck.checked) {
                var histogramMpvItem = scopeLoader.item.histogramMpvLoader.item;
                if (histogramMpvItem && histogramMpvItem.mpvPlayer) {
                    // Apply filter first, then load video
                    try {
                        histogramMpvItem.mpvPlayer.command(["loadfile", currentFile]);
                        // Delayed execution with timer
                        histogramTimer.targetMpv = histogramMpvItem.mpvPlayer;
                        histogramTimer.restart();
                    } catch (e) {
                        console.error("Failed to update histogram:", e);
                    }
                }
            }
            
            // Update vectorscope
            if (vectorscopeCheck.checked) {
                var vectorscopeMpvItem = scopeLoader.item.vectorscopeMpvLoader.item;
                if (vectorscopeMpvItem && vectorscopeMpvItem.mpvPlayer) {
                    // Apply filter first, then load video
                    try {
                        vectorscopeMpvItem.mpvPlayer.command(["loadfile", currentFile]);
                        // Delayed execution with timer
                        vectorscopeTimer.targetMpv = vectorscopeMpvItem.mpvPlayer;
                        vectorscopeTimer.restart();
                    } catch (e) {
                        console.error("Failed to update vectorscope:", e);
                    }
                }
            }
        } catch (e) {
            console.error("Failed to update scopes:", e);
            statusText.text = "Failed to update scopes";
        }
    }
}
