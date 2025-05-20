import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import Utils 1.0 as Utils

// Import local components
import mpv 1.0
import "components"
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
    color: "#161616"  // Dark theme background
    
    // Global properties
    property bool mpvSupported: hasMpvSupport
    property string currentMediaFile: ""
    property bool settingsPanelVisible: true
    property int currentFrame: 0
    property int totalFrames: 1000
    property real fps: 24.0
    property string currentTimecode: "00:00:00:00"
    property bool magnifierActive: false
    property bool scopesPanelVisible: false
    
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
    
    // 디버그용 경계선 표시 활성화
    property bool showDebugBorders: true
    
    // 레이아웃 디버그 함수
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
    
    // 전체 화면 레이아웃을 단순화
    Rectangle {
        id: mainContentArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusBar.top
        color: "#161616"
        
        // 디버그용 경계선
        Rectangle {
            visible: showDebugBorders
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: "red"
            z: 100
        }
        
        // 비디오 영역과 설정 패널을 나란히 배치
        SplitView {
            anchors.fill: parent
            orientation: Qt.Horizontal
            
            // 비디오 영역
            Item {
                id: videoContainer
                SplitView.fillWidth: true
                SplitView.minimumWidth: 400
                
                // 디버그용 경계선
                Rectangle {
                    visible: showDebugBorders
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: "green"
                    z: 100
            }
            
                // 비디오 영역 컴포넌트
            VideoArea {
                id: videoArea
                    anchors.fill: parent
                
                    // 동기화 속성
                currentMediaFile: root.currentMediaFile
                currentFrame: root.currentFrame
                totalFrames: root.totalFrames
                fps: root.fps
                currentTimecode: root.currentTimecode
                }
            }
            
            // 설정 패널
            Rectangle {
                id: settingsPanel
                color: panelColor
                SplitView.preferredWidth: panelWidth
                visible: settingsPanelVisible
                
                // 디버그용 경계선
                                        Rectangle {
                    visible: showDebugBorders
                                                anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: "blue"
                    z: 100
                }
                
                // 설정 패널 컨텐츠
                SettingsPanel {
                                        anchors.fill: parent
                    accentColor: root.accentColor
                    secondaryColor: root.secondaryColor
                    textColor: root.textColor
                    panelColor: root.panelColor
                    controlBgColor: root.controlBgColor
                    darkControlColor: root.darkControlColor
                    borderColor: root.borderColor
                    mainFont: root.mainFont
                    monoFont: root.monoFont
                    mpvPlayer: videoArea.mpvPlayer
                    fps: root.fps
                }
            }
        }
    }
    
    // 상태 바
    StatusBar {
        id: statusBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomControlBar.top
        height: 24  // 고정 높이
        visible: true  // 항상 표시
        
        currentMediaFile: root.currentMediaFile
        currentFrame: root.currentFrame
        totalFrames: root.totalFrames
        mainFont: root.mainFont
        monoFont: root.monoFont
        borderColor: root.borderColor
        darkControlColor: root.darkControlColor
        
        // 디버그용 경계선
        Rectangle {
            visible: showDebugBorders
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: "magenta"
            z: 100
        }
    }
    
    // 하단 컨트롤 바
    ControlBar {
        id: bottomControlBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 130  // 타임라인 포함한 높이 증가 (90+40)
        
        // 속성 연결
        mpvObject: videoArea.mpvPlayer
        currentFrame: root.currentFrame
        totalFrames: root.totalFrames
        fps: root.fps
        mpvSupported: root.mpvSupported
        
        // 디버그용 경계선
        Rectangle {
            visible: showDebugBorders
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: "yellow"
            z: 100
        }
        
        // 타임라인 바를 컨트롤바의 timelineArea에 배치
        FrameTimelineBar {
            id: timelineBar
            anchors.fill: parent.children[0]  // timelineArea에 맞춤
            visible: true  // 항상 표시
            
            mpvObject: videoArea.mpvPlayer
            
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            isPlaying: videoArea.mpvPlayer ? videoArea.mpvPlayer.isPlaying : false
            
            // 디버그용 경계선
            Rectangle {
                visible: showDebugBorders
                anchors.fill: parent
                color: "transparent"
                border.width: 2
                border.color: "cyan"
                z: 100
            }
            
            onSeekRequested: function(frame) {
                if (videoArea.mpvPlayer) {
                    videoArea.mpvPlayer.pause();
                    videoArea.mpvPlayer.seekToFrame(frame);
                    currentFrame = frame;
                    updateFrameInfo();
                }
            }
        }
        
        onOpenFileRequested: openOsFileExplorer()
        onToggleSettingsPanelRequested: settingsPanelVisible = !settingsPanelVisible
        onToggleFullscreenRequested: function() {
                                if (root.visibility === Window.FullScreen) {
                                    root.showNormal();
                                } else {
                                    root.showFullScreen();
                                }
                            }
        onTakeScreenshotRequested: {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.command(["screenshot"]);
            }
        }
        onToggleScopesRequested: scopesPanelVisible = !scopesPanelVisible
        onFrameBackwardRequested: function(frames) {
            goBackFrames(frames);
        }
        onFrameForwardRequested: function(frames) {
            goForwardFrames(frames);
        }
    }
    
    // 파일 시스템 열기 함수
    function openOsFileExplorer() {
        console.log("파일 열기 요청됨");
        
        // 실제 시스템 파일 탐색기를 여는 MPV 명령 실행
        try {
            // 네이티브 파일 다이얼로그를 열기 위한 스크립트 메시지 전송
            if (videoArea && videoArea.mpvPlayer) {
                videoArea.mpvPlayer.command(["script-message-to", "ipc", "open-file-dialog"]);
                
                // 또는 다른 방법으로 직접 MPV 명령어 실행
                // videoArea.mpvPlayer.command(["script-binding", "console/enable"]);
                videoArea.mpvPlayer.command(["script-binding", "open-file-dialog"]);
            } else {
                console.error("MPV 플레이어 인스턴스를 찾을 수 없음");
                
                // 대체 방법: 샘플 비디오 로드
                var testFilePath = "sample_video.mp4";
                console.log("대체 방식: 테스트 영상 로드: " + testFilePath);
                currentMediaFile = testFilePath;
                
                if (videoArea && videoArea.mpvPlayer) {
                    videoArea.mpvPlayer.command(["loadfile", testFilePath]);
                }
                
                currentFrame = 0;
                updateFrameInfo();
            }
        } catch (e) {
            console.error("파일 탐색기 열기 실패:", e);
        }
    }
    
    // 파일 드롭 지원
    DropArea {
                        anchors.fill: parent
        onDropped: function(drop) {
            if (drop.hasUrls) {
                var filePath = drop.urls[0];
                console.log("File dropped:", filePath);
                playMedia(filePath);
                    }
                }
            }
            
    // 컬러피커 다이얼로그
    ColorPickerDialog {
        id: colorPickerDialog
        anchors.centerIn: parent
        
        controlBgColor: root.controlBgColor
        borderColor: root.borderColor
        textColor: root.textColor
        mainFont: root.mainFont
        monoFont: root.monoFont
        
        onColorSelected: function(color) {
            console.log("Selected color:", color);
        }
    }
    
    // 확대 도구
    MagnifierTool {
        id: magnifierTool
        visible: magnifierActive
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
    }

    ScopePanel {
        id: scopePanel
        visible: scopesPanelVisible
        mpvPlayer: videoArea.mpvPlayer
        anchors.right: parent.right
        anchors.bottom: bottomControlBar.top
        anchors.margins: 10
    }
    
    // 초기화
    Component.onCompleted: {
        console.log("앱 초기화 완료");
        updateFrameInfo();
        
        // 초기 디버그 정보 출력
        console.log("MPV 지원 여부:", mpvSupported);
        
        // MPV 객체 정보
        if (videoArea && videoArea.mpvPlayer) {
            console.log("MPV 플레이어 객체가 생성됨");
        } else {
            console.log("MPV 플레이어 객체가 생성되지 않음");
        }
    }
    
    // 키보드 단축키
    Item {
        focus: true
        Keys.onPressed: function(event) {
            if (mpvSupported && videoArea.mpvPlayer) {
                if (event.key === Qt.Key_Space) {
                    videoArea.mpvPlayer.playPause();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    if (root.visibility === Window.FullScreen) {
                        root.showNormal();
                    } else {
                        Qt.quit();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_F) {
                    if (root.visibility === Window.FullScreen) {
                        root.showNormal();
                    } else {
                        root.showFullScreen();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    goBackFrames(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    goForwardFrames(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_O && (event.modifiers & Qt.ControlModifier)) {
                    // Ctrl+O 단축키로 파일 열기
                    openOsFileExplorer();
                    event.accepted = true;
                }
            }
        }
    }
    
    // 미디어 재생 함수
    function playMedia(filePath) {
        if (!mpvSupported || !videoArea.mpvPlayer) return;
        
        // MediaFunctions 사용
        let result = Utils.MediaFunctions.playMedia(videoArea.mpvPlayer, filePath, currentMediaFile);
        if (result) {
            // 파일 경로 업데이트
            currentMediaFile = result;
        
            // 재생 후 첫 프레임을 보여주기 위해 잠시 재생했다가 일시정지
            videoArea.mpvPlayer.play();
            playPauseTimer.restart();
        }
    }
    
    // 데모 비디오 재생
    function playDemoVideo(demoFile) {
        // 샘플 비디오 로드
        console.log("데모 비디오 재생:", demoFile);
        
        // 기본값 설정
        currentMediaFile = demoFile || "sample_video.mp4";
        fps = 24.0;
        totalFrames = 1440; // 24fps에서 1분
        currentFrame = 0;
        
        // MPV 플레이어로 직접 로드
        if (videoArea.mpvPlayer) {
            try {
                console.log("MPV 플레이어에 직접 로드중...");
                videoArea.mpvPlayer.command(["loadfile", currentMediaFile]);
        videoArea.mpvPlayer.play();
            } catch (e) {
                console.error("비디오 로드 실패:", e);
            }
        } else {
            console.log("MPV 플레이어가 초기화되지 않음");
        }
        
        // UI 업데이트
        updateFrameInfo();
    }
    
    // 미디어 로드 타이머
    Timer {
        id: playPauseTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (videoArea.mpvPlayer) {
                videoArea.mpvPlayer.pause();
                updateFrameInfo();
            }
        }
    }
    
    // 프레임 정보 업데이트
    function updateFrameInfo() {
        if (videoArea.mpvPlayer) {
            let result = Utils.MediaFunctions.updateFrameInfo(
                videoArea.mpvPlayer, 
                fps, 
                totalFrames, 
                currentFrame, 
                currentTimecode
            );
                
            if (result) {
                fps = result.fps;
                totalFrames = result.totalFrames;
                currentFrame = result.currentFrame;
                currentTimecode = result.currentTimecode;
            }
        }
    }
    
    // 프레임 탐색 함수
    function goBackFrames(numFrames) {
        Utils.MediaFunctions.goBackFrames(videoArea.mpvPlayer, fps, numFrames);
        frameUpdateTimer.restart();
    }
    
    function goForwardFrames(numFrames) {
        Utils.MediaFunctions.goForwardFrames(videoArea.mpvPlayer, fps, numFrames);
        frameUpdateTimer.restart();
    }
    
    // 프레임 업데이트 타이머
    Timer {
        id: frameUpdateTimer
        interval: 16
        repeat: false
        onTriggered: {
            try {
                updateFrameInfo();
            } catch (e) {
                console.error("프레임 업데이트 오류:", e);
            }
        }
    }
    
    // 위치 업데이트 타이머
    Timer {
        id: qmlGlobalTimer
        interval: 33
        running: videoArea.mpvPlayer && videoArea.mpvPlayer.filename !== ""
        repeat: true
        onTriggered: {
            try {
                if (videoArea.mpvPlayer && videoArea.mpvPlayer.filename && videoArea.mpvPlayer.filename !== "") {
                    updateFrameInfo();
    }
            } catch (e) {
                console.error("위치 업데이트 오류:", e);
} 
        }
    }
} 
