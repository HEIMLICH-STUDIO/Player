import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 상대 경로를 사용하여 필요한 컴포넌트 임포트
import "../ui"
import "../utils"
import "../widgets"

// 비디오 플레이어 메인 컴포넌트
Item {
    id: root
    
    // 내부 참조 프로퍼티
    property alias videoArea: videoArea
    property alias controlBar: controlBar
    property alias statusBar: statusBar
    property bool isFullscreen: false
    
    // 설정 창
    SettingsPanel {
        id: settingsWindow
        visible: false
        mpvObject: videoArea ? (videoArea.mpvSupported ? videoArea.mpvLoader.item.mpvPlayer : null) : null
    }
    
    // 메인 레이아웃 - 비디오 영역과 컨트롤 영역 분리
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0
        
        // 비디오 화면 영역 (레이아웃에서 늘어나도록 설정)
        VideoArea {
            id: videoArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // 비디오 관련 이벤트 처리
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
        
        // 타임라인/컨트롤 바
        ControlBar {
            id: controlBar
            Layout.fillWidth: true
            isPlaying: videoArea.isPlaying
            
            // 컨트롤 버튼 이벤트 처리
            onOpenFileRequested: videoArea.openFile()
            onPlayPauseRequested: videoArea.playPause()
            onFrameBackRequested: videoArea.stepBackward()
            onFrameForwardRequested: videoArea.stepForward()
            onSeekToFrameRequested: function(frame) {
                videoArea.seekToFrame(frame)
            }
            onFullscreenToggleRequested: {
                isFullscreen = !isFullscreen
                toggleFullscreen()
            }
            onSettingsToggleRequested: {
                // 대신 설정 창 열기
                if (!settingsWindow.visible) {
                    settingsWindow.show()
                }
            }
        }
        
        // 상태 바
        StatusBar {
            id: statusBar
            Layout.fillWidth: true
        }
    }
    
    // 전체화면 전환 함수
    function toggleFullscreen() {
        // 이 함수는 C++ 코드에서 구현 필요
        console.log("Fullscreen toggled:", isFullscreen)
    }
    
    // 외부에서 호출할 함수들
    function loadFile(path) {
        if (videoArea) {
            videoArea.loadFile(path)
        }
    }
    
    Component.onCompleted: {
        console.log("VideoPlayer initialized")
    }
} 