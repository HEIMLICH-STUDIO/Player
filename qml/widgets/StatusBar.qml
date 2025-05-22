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
    property int currentFrame: 0
    property int totalFrames: 0
    property real fps: 24.0
    property string currentFile: ""
    property string timecode: "00:00:00:00"
  property int timecodeFormat: 0 // 0: SMPTE Non-Drop, 1: SMPTE Drop-Frame, 2: HH:MM:SS.MS, 3: Frames Only, 4: Custom
    property var mpvObject: null  // mpv 객체 참조
    property bool useEmbeddedTimecode: false
    property int timecodeOffset: 0
    property string customTimecodePattern: "%H:%M:%S.%f"
    
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
            text: formatTimecodeDisplay()
            color: ThemeManager.textColor
            font.family: ThemeManager.monoFont
            font.pixelSize: ThemeManager.smallFontSize
        }
    }
    
    // 타임코드 표시 형식 결정 함수
    function formatTimecodeDisplay() {
        if (!timecode || timecode.length === 0) {
            return "TC: 00:00:00:00";
        }
        
        // 특수 형식 표시
        switch (timecodeFormat) {
            case 0: // SMPTE Non-Drop (HH:MM:SS:FF)
                return "TC: " + timecode;
            case 1: // SMPTE Drop-Frame (HH:MM:SS;FF)
                return "TC: " + timecode;
            case 2: // 밀리초 (HH:MM:SS.MS)
                return "TC: " + timecode;
            case 3: // 프레임 번호만
                return "Frame: " + currentFrame;
            case 4: // 커스텀 형식
                return "TC: " + timecode;
            default:
                return "TC: " + timecode;
        }
    }
    
    // mpv 객체로부터 타임코드 업데이트 수신
    Connections {
        target: mpvObject
        
        // 타임코드 변경 이벤트 처리
        function onTimecodeChanged(newTimecode) {
            timecode = newTimecode;
        }
        
        // 타임코드 형식 변경 이벤트 처리
        function onTimecodeFormatChanged(format) {
            timecodeFormat = format;
        }
        
        // 타임코드 오프셋 변경 이벤트 처리
        function onTimecodeOffsetChanged(offset) {
            timecodeOffset = offset;
        }
        
        // 커스텀 타임코드 패턴 변경 이벤트 처리
        function onCustomTimecodePatternChanged(pattern) {
            customTimecodePattern = pattern;
        }
    }
}