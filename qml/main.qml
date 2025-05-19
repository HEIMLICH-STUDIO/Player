import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform

// MPV 지원이 있을 때만 MpvPlayer 모듈 임포트
import mpv 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 720
    minimumWidth: 640
    minimumHeight: 480
    title: qsTr("HYPER-PLAYER")
    color: "black"  // 검은색 배경

    // MPV 지원 없음 메시지
    property bool mpvSupported: hasMpvSupport
    
    // 현재 로드된 미디어 파일 이름 저장
    property string currentMediaFile: ""
    
    // 디버그용 배경 - 확실히 눈에 보이도록
    Rectangle {
        id: debugBackground
        anchors.fill: parent
        color: "green"  // 녹색 배경으로 비디오 영역 확인
        opacity: 0.2
        z: 1
    }
    
    // 비디오 영역 - 직접 MpvObject를 만들어 사용
    MpvObject {
        id: mpvObject
        anchors.fill: parent
        z: 10  // 배경보다 위에 배치
        
        // 비디오 회전 수정 - 180도 회전 문제 해결
        transform: Rotation {
            origin.x: mpvObject.width/2
            origin.y: mpvObject.height/2
            angle: 180
        }
        
        // 디버그용 경계선
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: "red"
            z: 200
        }
        
        // 초기화 및 변경 이벤트 핸들러
        Component.onCompleted: {
            console.log("MPV object initialized with size:", width, "x", height);
        }
        
        onFilenameChanged: {
            console.log("Filename changed to:", filename);
        }
        
        onPauseChanged: {
            console.log("Pause state changed to:", pause);
        }
    }
    
    // 직접 참조 MpvObject를 mpvPlayer로 별명 설정
    property alias mpvPlayer: mpvObject
    
    // 미디어 플레이 함수
    function playMedia(filePath) {
        if (!mpvSupported || !mpvPlayer) return;
        
        console.log("Playing media:", filePath);
        
        // 파일 경로 정규화 (file:/// 제거)
        let normalizedPath = filePath.toString();
        if (normalizedPath.startsWith("file:///")) {
            normalizedPath = normalizedPath.slice(8); // Windows의 경우 file:///C:/ -> C:/
        }
        
        currentMediaFile = normalizedPath;
        mpvPlayer.command(["loadfile", normalizedPath]);
        mpvPlayer.play();
    }

    // Key handling
    Item {
        focus: true
        Keys.onPressed: function(event) {
            if (mpvSupported && mpvPlayer) {
                if (event.key === Qt.Key_Space) {
                    mpvPlayer.playPause()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    if (root.visibility === Window.FullScreen) {
                        root.showNormal()
                    } else {
                        Qt.quit()
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_F) {
                    if (root.visibility === Window.FullScreen) {
                        root.showNormal()
                    } else {
                        root.showFullScreen()
                    }
                    event.accepted = true
                }
            }
        }
    }
    
    // 테스트 파일 열기 버튼
    Rectangle {
        width: 200
        height: 40
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        color: "#2196F3"
        radius: 4
        z: 200
        
        Text {
            anchors.centerIn: parent
            text: "파일 열기"
            color: "white"
            font.pixelSize: 16
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: fileDialog.open()
        }
    }
    
    // 파일 선택 다이얼로그
    FileDialog {
        id: fileDialog
        title: "비디오 파일 선택"
        nameFilters: ["비디오 파일 (*.mp4 *.avi *.mkv *.mov *.wmv *.webm)"]
        
        onAccepted: {
            console.log("Selected file:", fileDialog.file);
            playMedia(fileDialog.file);
        }
    }
    
    // Main content area
    Item {
        id: mainContent
        anchors.fill: parent

        // Open file button (only shown when no video is playing)
        Button {
            id: openFileBtn
            anchors.centerIn: parent
            text: "Open Media File"
            visible: !mpvPlayer || !mpvPlayer.filename || mpvPlayer.filename === ""
            z: 10
            
            onClicked: fileDialog.open()
            
            background: Rectangle {
                color: parent.hovered ? "#3080FF" : "#2060D0"
                radius: 5
                implicitWidth: 150
                implicitHeight: 40
                border.color: "#40000000"
                border.width: 1
            }
            
            contentItem: Text {
                text: parent.text
                color: "white"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        
        // Debug rectangle behind video to see if MPV is actually rendering
        Rectangle {
            anchors.fill: parent
            color: "blue"
            opacity: 0.3
            z: 0
        }
        
        // Simple controls overlay (always visible)
        Rectangle {
            id: controlsBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 60
            color: Qt.rgba(0.1, 0.1, 0.1, 0.7)
            z: 5
            
            Row {
                anchors.centerIn: parent
                spacing: 20
                
                // Play/Pause button
                Button {
                    width: 50
                    height: 50
                    
                    background: Rectangle {
                        color: "#3080FF"
                        radius: width / 2
                    }
                    
                    contentItem: Text {
                        text: mpvPlayer && mpvPlayer.pause ? "▶" : "⏸"
                        color: "white"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        if (mpvPlayer) {
                            mpvPlayer.playPause()
                        } else if (mpvSupported) {
                            fileDialog.open()
                        }
                    }
                }
                
                // Open file button
                Button {
                    width: 40
                    height: 40
                    
                    background: Rectangle {
                        color: "transparent"
                        border.color: "white"
                        border.width: 1
                        radius: 5
                    }
                    
                    contentItem: Text {
                        text: "📂"
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: fileDialog.open()
                }
                
                // Fullscreen button
                Button {
                    width: 40
                    height: 40
                    
                    background: Rectangle {
                        color: "transparent"
                        border.color: "white"
                        border.width: 1
                        radius: 5
                    }
                    
                    contentItem: Text {
                        text: "⛶"
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        if (root.visibility === Window.FullScreen) {
                            root.showNormal()
                        } else {
                            root.showFullScreen()
                        }
                    }
                }
                
                // Exit button
                Button {
                    width: 40
                    height: 40
                    
                    background: Rectangle {
                        color: "transparent"
                        border.color: "white"
                        border.width: 1
                        radius: 5
                    }
                    
                    contentItem: Text {
                        text: "✕"
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: Qt.quit()
                }
            }
        }
        
        // Basic info text (filename and duration)
        Rectangle {
            id: infoBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 40
            color: Qt.rgba(0.1, 0.1, 0.1, 0.7)
            visible: mpvPlayer && mpvPlayer.filename && mpvPlayer.filename !== ""
            z: 5
            
            Text {
                anchors.centerIn: parent
                text: currentMediaFile ? currentMediaFile.split('/').pop() : ""
                color: "white"
                font.pixelSize: 14
                elide: Text.ElideMiddle
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
} 