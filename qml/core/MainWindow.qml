import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import "../utils"

// 메인 윈도우 - 앱의 진입점
Window {
    id: root
    visible: true
    width: 1280
    height: 720
    minimumWidth: 800
    minimumHeight: 600
    title: "Player by HEIMLICH®"
    color: ThemeManager.backgroundColor
    
    // 전체화면 상태
    property bool isFullScreen: false
    
    // 메인 비디오 플레이어 컴포넌트
    VideoPlayer {
        id: videoPlayer
        anchors.fill: parent
        
        // 전체화면 이벤트 연결
        onIsFullscreenChanged: {
            root.toggleFullScreen()
        }
    }
    
    // 파일 다이얼로그 추가
    FileDialog {
        id: fileDialog
        title: "Open Video File"
        nameFilters: ["Video files (*.mp4 *.mkv *.avi *.mov *.wmv *.flv)"]
        onAccepted: {
            videoPlayer.loadFile(fileDialog.fileUrl)
        }
    }
    
    // 키보드 이벤트 핸들링
    Item {
        anchors.fill: parent
        focus: true
        
        Keys.onPressed: function(event) {
            // 전체 화면 전환 (F11 또는 F)
            if (event.key === Qt.Key_F11 || (event.key === Qt.Key_F && event.modifiers === Qt.NoModifier)) {
                root.toggleFullScreen()
                event.accepted = true
            }
            
            // ESC로 전체화면 해제
            else if (event.key === Qt.Key_Escape && root.isFullScreen) {
                root.isFullScreen = false
                root.showNormal()
                event.accepted = true
            }
            
            // 파일 열기 (Ctrl+O)
            else if (event.key === Qt.Key_O && event.modifiers === Qt.ControlModifier) {
                fileDialog.open()
                event.accepted = true
            }
            
            // 재생/일시정지 (Space)
            else if (event.key === Qt.Key_Space) {
                videoPlayer.videoArea.playPause()
                event.accepted = true
            }
        }
    }
    
    // 전체화면 전환 함수
    function toggleFullScreen() {
        if (!isFullScreen) {
            showFullScreen()
            isFullScreen = true
        } else {
            showNormal()
            isFullScreen = false
        }
    }
    
    // 파일 열기 함수 - 외부에서 호출 가능
    function openFile(path) {
        videoPlayer.loadFile(path)
    }
    
    // 컴포넌트 초기화
    Component.onCompleted: {
        console.log("MainWindow initialized")
        
        // 앱 시작 시 모든 컴포넌트가 로드된 후에 색상 초기화
        Qt.callLater(function() {
            // 컬러 테마 강제 새로고침
            ThemeManager.refreshColors()
            
            // 모든 아이콘이 제대로 렌더링되도록 직접 VideoPlayer 갱신 요청
            if (videoPlayer && videoPlayer.controlBar) {
                console.log("Refreshing control bar UI")
                videoPlayer.controlBar.visible = false
                videoPlayer.controlBar.visible = true
            }
        })
    }
} 