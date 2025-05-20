import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../utils"
import "../ui"

// 플레이어 컨트롤 바 + 타임라인
Rectangle {
    id: root
    color: ThemeManager.controlBgColor
    height: 130  // 타임라인(40) + 컨트롤(90)
    
    // 프로퍼티
    property alias frameTimeline: timelineBar
    property bool isPlaying: false
    property int currentFrame: 0
    property int totalFrames: 0
    property real fps: 24.0
    
    // 시그널
    signal openFileRequested()
    signal playPauseRequested()
    signal frameBackRequested()
    signal frameForwardRequested()
    signal seekToFrameRequested(int frame)
    signal fullscreenToggleRequested()
    signal settingsToggleRequested()
    
    // 타임라인 영역
    Item {
        id: timelineArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 40
        
        // 타임라인 바
        FrameTimelineBar {
            id: timelineBar
            anchors.fill: parent
            
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            isPlaying: root.isPlaying
            
            // 시크 요청 처리
            onSeekRequested: function(frame) {
                seekToFrameRequested(frame);
            }
        }
    }
    
    // 경계선
    Rectangle {
        anchors.top: timelineArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: ThemeManager.borderColor
    }
    
    // 컨트롤 버튼 영역
    Item {
        anchors.top: timelineArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        
        // 좌측 컨트롤
        Row {
            id: leftControls
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            // 파일 열기 버튼
            IconButton {
                iconSource: "folder"
                iconSize: 18
                onClicked: openFileRequested()
                
                ToolTip.visible: hovered
                ToolTip.text: "Open File"
            }
        }
        
        // 중앙 컨트롤
        Row {
            anchors.centerIn: parent
            spacing: 12
            
            // 프레임 뒤로 10개
            IconButton {
                iconSource: "backward"
                iconSize: 18
                onClicked: frameBackRequested()
                
                ToolTip.visible: hovered
                ToolTip.text: "Step Back 10 Frames"
            }
            
            // 프레임 뒤로 1개
            IconButton {
                iconSource: "prev"
                iconSize: 18
                onClicked: {
                    // 한 프레임만 뒤로
                    frameBackRequested();
                }
                
                ToolTip.visible: hovered
                ToolTip.text: "Previous Frame"
            }
            
            // 재생/일시정지
            IconButton {
                iconSource: isPlaying ? "pause" : "play"
                iconSize: 28
                width: 48
                height: 48
                
                // 배경 있는 버튼
                bgColorNormal: ThemeManager.accentColor
                textColorNormal: "white"
                
                onClicked: playPauseRequested()
                
                ToolTip.visible: hovered
                ToolTip.text: isPlaying ? "Pause" : "Play"
            }
            
            // 프레임 앞으로 1개
            IconButton {
                iconSource: "next"
                iconSize: 18
                onClicked: {
                    // 한 프레임만 앞으로
                    frameForwardRequested();
                }
                
                ToolTip.visible: hovered
                ToolTip.text: "Next Frame"
            }
            
            // 프레임 앞으로 10개
            IconButton {
                iconSource: "forward"
                iconSize: 18
                onClicked: frameForwardRequested()
                
                ToolTip.visible: hovered
                ToolTip.text: "Step Forward 10 Frames"
            }
        }
        
        // 우측 컨트롤
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            // 설정 버튼
            IconButton {
                iconSource: "settings"
                iconSize: 18
                onClicked: settingsToggleRequested()
                
                ToolTip.visible: hovered
                ToolTip.text: "Settings"
            }
            
            // 전체화면 버튼
            IconButton {
                iconSource: "fullscreen"
                iconSize: 18
                onClicked: fullscreenToggleRequested()
                
                ToolTip.visible: hovered
                ToolTip.text: "Fullscreen"
            }
        }
        
        // 현재 프레임/총 프레임 표시
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            
            text: "Frame: " + currentFrame + " / " + totalFrames
            color: ThemeManager.textColor
            font.family: ThemeManager.monoFont
            font.pixelSize: ThemeManager.smallFontSize
        }
    }
} 