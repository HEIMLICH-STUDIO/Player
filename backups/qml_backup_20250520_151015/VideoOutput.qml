import QtQuick
import mpv 1.0

// 비디오 출력 컴포넌트
Item {
    id: videoOutput
    anchors.fill: parent

    // MPV 객체 직접 노출
    property alias mpvObject: mpvObj

    // 비디오가 로드되었는지 여부
    property bool hasVideo: false

    // 디버그를 위한 테두리
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "blue"
        border.width: 3
        z: 10
    }

    // MPV 객체
    MpvObject {
        id: mpvObj
        anchors.fill: parent
        z: 5
        
        // 비디오 레디 이벤트 핸들러
        onVideoReady: {
            console.log("Video is ready")
            videoOutput.hasVideo = true
        }

        // 파일 로드 시 이벤트
        onFilenameChanged: {
            console.log("Filename changed to:", filename)
        }

        // 초기화 완료 이벤트
        Component.onCompleted: {
            console.log("MPV object initialized with size:", width, "x", height)
        }
    }

    // 디버그용 플레이어 상태 표시
    Rectangle {
        id: statusIndicator
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        width: 20
        height: 20
        color: mpvObj.playing ? "green" : "red"
        opacity: 0.8
        z: 20
    }

    // 비디오 없을 때 메시지
    Text {
        anchors.centerIn: parent
        text: "No video loaded"
        color: "white"
        font.pixelSize: 24
        visible: !videoOutput.hasVideo
        z: 15
    }
} 