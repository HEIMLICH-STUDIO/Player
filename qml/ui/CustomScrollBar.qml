import QtQuick
import QtQuick.Controls

import "../utils"

// 테마와 일치하는 커스텀 스크롤바
ScrollBar {
    id: control
    
    // 스크롤바 너비
    implicitWidth: ThemeManager.scrollBarWidth
    implicitHeight: orientation == Qt.Horizontal ? ThemeManager.scrollBarWidth : 200
    
    // 스크롤바가 필요할 때만 표시하거나 항상 표시
    policy: ScrollBar.AsNeeded
    
    // 스크롤바 트랙 (배경)
    background: Rectangle {
        color: ThemeManager.scrollBarBgColor
        radius: ThemeManager.scrollBarRadius
        opacity: control.active || control.hovered ? 0.7 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
    
    // 스크롤바 핸들 (드래그 가능한 부분)
    contentItem: Rectangle {
        implicitWidth: ThemeManager.scrollBarWidth
        implicitHeight: 100
        radius: ThemeManager.scrollBarRadius
        
        // 테마의 색상 사용
        color: control.pressed ? ThemeManager.scrollBarActiveColor : 
               control.hovered ? ThemeManager.scrollBarHoverColor : 
               ThemeManager.scrollBarColor
        
        // 투명도 애니메이션
        opacity: control.policy === ScrollBar.AlwaysOn || 
                (control.active && control.size < 1.0) || 
                control.hovered ? 1.0 : 0.7
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
    
    // 마우스 휠 지원
    interactive: true
} 