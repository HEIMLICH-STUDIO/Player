import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

// 조건부 import - MPV와 TimelineSync 지원 확인
// 사용 전에 C++에서 hasMpvSupport 컨텍스트 프로퍼티 설정 필요
import "../utils" as Utils

// MPV 비디오 플레이어를 포함하는 영역
Item {
    id: root
    
    // 비디오 관련 속성
    property int frame: 0
    property int frames: 0
    property string filename: ""
    property real fps: 24.0
    property bool isPlaying: false
    
    // 시그널 (주의: 중복을 피하기 위해 네이밍 변경)    
    signal onFrameChangedEvent(int frame)
    signal onTotalFramesChangedEvent(int frames)
    signal onFileChangedEvent(string filename)
    signal onFpsChangedEvent(real fps)
    
    // MPV 지원 여부 (C++에서 rootContext에 설정)
    property bool mpvSupported: typeof hasMpvSupport !== "undefined" ? hasMpvSupport : false
    
    // 다크 테마 배경
    Rectangle {
        anchors.fill: parent
        color: "#121212" // 완전 검은색 배경
        z: -1 // MPV 플레이어보다 뒤에 위치
    }
    
    // 메시지 오버레이 (에러 등 표시)
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
            font.pixelSize: 14
            text: ""
        }
        
        // 자동으로 메시지 숨기기
        Timer {
            id: messageTimer
            interval: 3000
            running: messageText.text !== ""
            onTriggered: messageText.text = ""
        }
    }
    
    // MPV 지원이 없을 때 표시할 플레이스홀더
    Rectangle {
        id: placeholderRect
        anchors.fill: parent
        color: "#121212"
        visible: !mpvSupported
        
        Column {
            anchors.centerIn: parent
            spacing: 10
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MPV support not available"
                color: "white"
                font.pixelSize: 18
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Add HAVE_MPV definition during build"
                color: "#aaaaaa"
                font.pixelSize: 14
            }
            
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Open File (Placeholder)"
                onClicked: showMessage("MPV support required to play videos")
            }
        }
    }
    
    // 파일 다이얼로그
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
    
    // MPV 지원이 있을 때 동적으로 생성되는 컴포넌트
    Loader {
        id: mpvLoader
        anchors.fill: parent
        active: mpvSupported
        sourceComponent: mpvSupported ? mpvComponent : null
    }
    
    // MPV 컴포넌트 정의 - 조건부 로드
    Component {
        id: mpvComponent
        
        Item {
            // MPV 및 TimelineSync는 import 가능한 경우에만 사용
            property var mpvPlayer: null
            property var timelineSync: null
            
            Component.onCompleted: {
                // 동적으로 컴포넌트 생성 시도
                try {
                    // MPV 컴포넌트 동적 생성 시도
                    var component = Qt.createQmlObject(
                        'import mpv 1.0; MpvObject { anchors.fill: parent }',
                        this,
                        "dynamically_created_mpv"
                    );
                    
                    if (component) {
                        mpvPlayer = component;
                        console.log("MPV component created successfully");
                        
                        // 이벤트 연결
                        connectMpvEvents();
                    }
                    
                    // TimelineSync 동적 생성 시도
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
            
            // MPV 이벤트 연결 함수
            function connectMpvEvents() {
                if (!mpvPlayer) return;
                
                mpvPlayer.positionChanged.connect(function(position) {
                    // 현재 프레임 업데이트
                    if (position >= 0 && root.fps > 0) {
                        var frame = Math.round(position * root.fps);
                        root.frame = frame;
                        root.onFrameChangedEvent(frame);
                    }
                });
                
                mpvPlayer.durationChanged.connect(function(duration) {
                    // 총 프레임 수 업데이트
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
                        
                        // FPS가 변경되면 총 프레임 수도 업데이트
                        if (mpvPlayer.duration > 0) {
                            var totalFrames = Math.ceil(mpvPlayer.duration * root.fps);
                            root.frames = totalFrames;
                            root.onTotalFramesChangedEvent(totalFrames);
                        }
                    }
                });
            }
        }
    }
    
    // 메시지 표시
    function showMessage(text) {
        messageText.text = text;
        messageTimer.restart();
    }
    
    // 파일 열기 다이얼로그
    function openFile() {
        if (mpvSupported) {
            fileDialog.open()
        } else {
            showMessage("MPV support not available")
        }
    }
    
    // 파일 불러오기
    function loadFile(path) {
        if (!mpvSupported) {
            showMessage("Cannot load file: MPV support not available");
            return;
        }
        
        try {
            var mpvPlayer = mpvLoader.item ? mpvLoader.item.mpvPlayer : null;
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
    
    // 재생/일시정지 전환
    function playPause() {
        if (!mpvSupported) {
            showMessage("Cannot play/pause: MPV support not available");
            return;
        }
        
        var mpvPlayer = mpvLoader.item ? mpvLoader.item.mpvPlayer : null;
        if (mpvPlayer) {
            mpvPlayer.playPause();
        }
    }
    
    // 프레임 단위 이동
    function stepForward() {
        if (!mpvSupported) {
            showMessage("Cannot step: MPV support not available");
            return;
        }
        
        var mpvPlayer = mpvLoader.item ? mpvLoader.item.mpvPlayer : null;
        if (mpvPlayer) {
            if (mpvPlayer.pause) {
                // 정지 상태에서는 프레임 단위 이동
                mpvPlayer.command(["frame-step"]);
            } else {
                // 재생 중에는 일단 멈추고 프레임 이동
                mpvPlayer.pause = true;
                mpvPlayer.command(["frame-step"]);
            }
        }
    }
    
    function stepBackward() {
        if (!mpvSupported) {
            showMessage("Cannot step: MPV support not available");
            return;
        }
        
        var mpvPlayer = mpvLoader.item ? mpvLoader.item.mpvPlayer : null;
        if (mpvPlayer) {
            if (mpvPlayer.pause) {
                // 정지 상태에서는 프레임 단위 이동
                mpvPlayer.command(["frame-back-step"]);
            } else {
                // 재생 중에는 일단 멈추고 프레임 이동
                mpvPlayer.pause = true;
                mpvPlayer.command(["frame-back-step"]);
            }
        }
    }
    
    // 특정 프레임으로 이동
    function seekToFrame(frame) {
        if (!mpvSupported) {
            showMessage("Cannot seek: MPV support not available");
            return;
        }
        
        var mpvPlayer = mpvLoader.item ? mpvLoader.item.mpvPlayer : null;
        if (mpvPlayer && fps > 0) {
            var position = frame / fps;
            mpvPlayer.command(["seek", position, "absolute", "exact"]);
        }
    }
    
    // 키보드 포커스
    focus: true
    Keys.onSpacePressed: playPause()
    Keys.onLeftPressed: stepBackward()
    Keys.onRightPressed: stepForward()
} 