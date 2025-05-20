import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../utils"

// 아이콘 버튼 컴포넌트
Rectangle {
    id: root
    
    // 크기 설정
    width: 36
    height: 36
    radius: 4
    
    // 스타일 속성
    property string iconSource: ""    // 아이콘 이름 (assets/icons/에서 로드)
    property int iconSize: 16         // 아이콘 크기
    property real iconOpacity: 1.0    // 아이콘 투명도
    
    // 색상 속성 - ThemeManager와 통합
    property color bgColorNormal: "transparent"
    property color bgColorHover: ThemeManager.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.1)
    property color bgColorPressed: ThemeManager.isDarkTheme ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.15)
    property color bgColorChecked: ThemeManager.isDarkTheme ? Qt.rgba(0, 0.4, 0.8, 0.2) : Qt.rgba(0, 0.4, 0.8, 0.1)
    
    property color textColorNormal: ThemeManager.controlIconColor
    property color textColorHover: ThemeManager.controlIconHoverColor
    property color textColorPressed: ThemeManager.accentColor
    property color textColorChecked: ThemeManager.accentColor
    
    // 상태 속성
    property bool enabled: true
    property bool hovered: mouseArea.containsMouse
    property bool pressed: mouseArea.pressed
    
    // 기능 속성
    property bool checkable: false
    property bool checked: false
    signal clicked()
    signal pressAndHold()
    
    // 툴팁 대체 텍스트
    property string tipText: ""
    property bool showTip: tipText !== "" && mouseArea.containsMouse
    
    // 배경색 바인딩
    color: {
        if (!enabled) {
            return Qt.rgba(bgColorNormal.r, bgColorNormal.g, bgColorNormal.b, 0.3);
        } else if (pressed) {
            return bgColorPressed;
        } else if (checked) {
            return bgColorChecked;
        } else if (hovered) {
            return bgColorHover;
        } else {
            return bgColorNormal;
        }
    }
    
    // 아이콘 색상 계산
    property color currentIconColor: {
        if (!enabled) {
            return Qt.rgba(textColorNormal.r, textColorNormal.g, textColorNormal.b, 0.5);
        } else if (pressed) {
            return textColorPressed;
        } else if (checked) {
            return textColorChecked;
        } else if (hovered) {
            return textColorHover;
        } else {
            return textColorNormal;
        }
    }
    
    // SVG 아이콘 이미지
    Image {
        id: icon
        anchors.centerIn: parent
        source: {
            if (!iconSource) return "";
            
            if (iconSource.startsWith("qrc:") || 
                iconSource.startsWith("/") || 
                iconSource.startsWith("file:") || 
                iconSource.startsWith("http")) {
                return iconSource;
            }
            
            // 로컬 경로 사용 (URL 형식 문제 수정)
            return "../../assets/icons/" + iconSource + ".svg";
        }
        width: iconSize
        height: iconSize
        sourceSize.width: iconSize * 1.5 // 더 선명한 렌더링을 위해 더 큰 소스 크기 사용
        sourceSize.height: iconSize * 1.5
        fillMode: Image.PreserveAspectFit
        opacity: enabled ? iconOpacity : 0.5
    }
    
    // 아이콘 색상 필터 (간소화된 방식)
    Rectangle {
        anchors.fill: icon
        color: "transparent"
        visible: ThemeManager.isDarkTheme
        
        Rectangle {
            anchors.fill: parent
            color: root.currentIconColor
            opacity: 0.8
            visible: icon.status === Image.Ready
        }
    }
    
    // 아이콘 텍스트 (아이콘 로드 실패 시 대체)
    Text {
        id: iconText
        anchors.centerIn: parent
        text: iconSource ? iconSource[0].toUpperCase() : "?"
        visible: icon.status !== Image.Ready
        color: root.currentIconColor
        font.pixelSize: iconSize
        font.bold: true
    }
    
    // 마우스 이벤트 처리
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            if (!root.enabled) return;
            if (root.checkable) {
                root.checked = !root.checked;
            }
            root.clicked();
        }
        
        onPressAndHold: {
            if (root.enabled) root.pressAndHold();
        }
    }
    
    // 툴팁
    Rectangle {
        id: toolTip
        visible: showTip
        opacity: showTip ? 1.0 : 0
        color: ThemeManager.panelColor
        radius: 4
        width: toolTipText.width + 16
        height: toolTipText.height + 10
        
        // 툴팁 위치는 버튼 아래
        x: (parent.width - width) / 2
        y: parent.height + 5
        
        // 경계선
        border.width: 1
        border.color: ThemeManager.borderColor
        
        // 툴팁 텍스트
        Text {
            id: toolTipText
            text: root.tipText
            anchors.centerIn: parent
            color: ThemeManager.textColor
            font.pixelSize: 12
        }
        
        // 애니메이션
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
    
    // 전환 애니메이션
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    Component.onCompleted: {
        console.log("IconButton created: " + iconSource);
    }
} 