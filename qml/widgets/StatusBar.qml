import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../utils"

// 상태바 컴포넌트
Rectangle {
    id: root
    width: parent.width
    height: 24
    color: ThemeManager.darkControlColor
    
    // 프로퍼티
    property string currentFile: ""
    property int currentFrame: 0
    property int totalFrames: 0
    property string timecode: "00:00:00:00"
    property real fps: 24.0  // Add fps property with default value
    
    // 상단 경계선
    Rectangle {
        width: parent.width
        height: 1
        color: ThemeManager.borderColor
        anchors.top: parent.top
    }
    
    // 상태 정보 표시
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10
        
        // 파일 이름
        Text {
            Layout.fillWidth: true
            text: currentFile ? currentFile.split('/').pop() : "No file loaded"
            color: ThemeManager.textColor
            font.pixelSize: ThemeManager.smallFontSize
            elide: Text.ElideMiddle
        }
        
        // 현재 프레임 / 총 프레임
        Text {
            text: "Frame: " + currentFrame + " / " + totalFrames
            color: ThemeManager.textColor
            font.family: ThemeManager.monoFont
            font.pixelSize: ThemeManager.smallFontSize
        }
        
        // 타임코드
        Text {
            text: "TC: " + timecode
            color: ThemeManager.textColor
            font.family: ThemeManager.monoFont
            font.pixelSize: ThemeManager.smallFontSize
        }
    }
    
    // 타임코드 계산 함수
    function updateTimecode() {
        if (totalFrames <= 0 || currentFrame < 0) {
            timecode = "00:00:00:00";
            return;
        }
        
        // 프레임에서 시간 계산
        var seconds = currentFrame / fps;
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = Math.floor(seconds % 60);
        var f = Math.floor((currentFrame % fps));
        
        // 포맷팅
        var hh = h.toString().padStart(2, '0');
        var mm = m.toString().padStart(2, '0');
        var ss = s.toString().padStart(2, '0');
        var ff = f.toString().padStart(2, '0');
        
        timecode = hh + ":" + mm + ":" + ss + ":" + ff;
    }
    
    // 프레임이 변경되면 타임코드 업데이트
    onCurrentFrameChanged: updateTimecode()
} 