import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "../utils"
import "../ui"

// 설정 패널 (별도 창으로 변경)
Window {
    id: root
    title: "HYPER-PLAYER Settings"
    width: 480
    height: 520
    minimumWidth: 450
    minimumHeight: 500
    color: ThemeManager.dialogColor
    
    // 모달 설정
    modality: Qt.ApplicationModal
    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    
    // 중앙 정렬
    Component.onCompleted: {
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
        console.log("Settings window initialized")
    }
    
    // MPV 참조
    property var mpvObject: null
    
    // 테두리와 그림자 효과
    Rectangle {
        id: contentArea
        anchors.fill: parent
        color: ThemeManager.dialogColor
        border.width: 1
        border.color: ThemeManager.borderColor
        radius: 6
        
        // 메인 레이아웃
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0
            
            // 탭 바
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: ThemeManager.tabBarColor
                
                TabBar {
                    id: tabBar
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    position: TabBar.Header
                    
                    background: Rectangle {
                        color: "transparent"
                    }
                    
                    // 일반 탭
                    TabButton {
                        height: 48
                        text: "General"
                        width: Math.max(100, implicitWidth)
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            font.weight: parent.checked ? Font.DemiBold : Font.Normal
                            color: parent.checked ? ThemeManager.tabButtonActiveTextColor : ThemeManager.tabButtonTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: "transparent"
                            
                            Rectangle {
                                width: parent.width
                                height: 3
                                anchors.bottom: parent.bottom
                                color: parent.parent.checked ? ThemeManager.tabButtonActiveColor : "transparent"
                            }
                        }
                    }
                    
                    // 비디오 탭
                    TabButton {
                        height: 48
                        text: "Video"
                        width: Math.max(100, implicitWidth)
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            font.weight: parent.checked ? Font.DemiBold : Font.Normal
                            color: parent.checked ? ThemeManager.tabButtonActiveTextColor : ThemeManager.tabButtonTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: "transparent"
                            
                            Rectangle {
                                width: parent.width
                                height: 3
                                anchors.bottom: parent.bottom
                                color: parent.parent.checked ? ThemeManager.tabButtonActiveColor : "transparent"
                            }
                        }
                    }
                    
                    // 오디오 탭
                    TabButton {
                        height: 48
                        text: "About"
                        width: Math.max(100, implicitWidth)
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            font.weight: parent.checked ? Font.DemiBold : Font.Normal
                            color: parent.checked ? ThemeManager.tabButtonActiveTextColor : ThemeManager.tabButtonTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: "transparent"
                            
                            Rectangle {
                                width: parent.width
                                height: 3
                                anchors.bottom: parent.bottom
                                color: parent.parent.checked ? ThemeManager.tabButtonActiveColor : "transparent"
                            }
                        }
                    }
                }
            }
            
            // 구분선
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: ThemeManager.borderColor
            }
            
            // 탭 컨텐츠
            StackLayout {
                id: stackLayout
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex
                
                // 일반 설정 탭
                Item {
                    id: generalTab
                    
                    // 설정 목록을 스크롤 가능하게
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 16
                        clip: true
                        
                        // 스크롤바 스타일링
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: ThemeManager.scrollBarWidth
                            
                            background: Rectangle {
                                color: ThemeManager.scrollBarBgColor
                                radius: ThemeManager.scrollBarRadius
                            }
                            
                            contentItem: Rectangle {
                                implicitWidth: ThemeManager.scrollBarWidth
                                radius: ThemeManager.scrollBarRadius
                                color: parent.pressed ? ThemeManager.scrollBarActiveColor : 
                                       parent.hovered ? ThemeManager.scrollBarHoverColor : 
                                       ThemeManager.scrollBarColor
                            }
                        }
                        
                        Column {
                            width: parent.width
                            spacing: 20
                            
                            // 섹션 타이틀
                            Text {
                                text: "Appearance"
                                color: ThemeManager.accentColor
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                            
                            // 외형 설정 항목들
                            Column {
                                width: parent.width
                                spacing: 16
                                
                                // 다크 모드
                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "Dark Theme"
                                        color: ThemeManager.textColor
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }
                                    
                                    Switch {
                                        checked: ThemeManager.isDarkTheme
                                        onCheckedChanged: {
                                            ThemeManager.setTheme(checked ? "dark" : "light")
                                        }
                                    }
                                }
                            }
                            
                            // 구분선
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: ThemeManager.borderColor
                                opacity: 0.5
                            }
                            
                            // 섹션 타이틀
                            Text {
                                text: "Playback"
                                color: ThemeManager.accentColor
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                            
                            // 플레이백 설정 항목들
                            Column {
                                width: parent.width
                                spacing: 16
                                
                                // 반복 재생
                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "Loop Playback"
                                        color: ThemeManager.textColor
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }
                                    
                                    Switch {
                                        checked: mpvObject ? mpvObject.loop : false
                                        onCheckedChanged: {
                                            if (mpvObject) {
                                                mpvObject.setLoopEnabled(checked);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 비디오 설정 탭
                Item {
                    id: videoTab
                    
                    // 설정 목록을 스크롤 가능하게
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 16
                        clip: true
                        
                        // 스크롤바 스타일링
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: ThemeManager.scrollBarWidth
                            
                            background: Rectangle {
                                color: ThemeManager.scrollBarBgColor
                                radius: ThemeManager.scrollBarRadius
                            }
                            
                            contentItem: Rectangle {
                                implicitWidth: ThemeManager.scrollBarWidth
                                radius: ThemeManager.scrollBarRadius
                                color: parent.pressed ? ThemeManager.scrollBarActiveColor : 
                                       parent.hovered ? ThemeManager.scrollBarHoverColor : 
                                       ThemeManager.scrollBarColor
                            }
                        }
                        
                        Column {
                            width: parent.width
                            spacing: 20
                            
                            // 섹션 타이틀
                            Text {
                                text: "Video Settings"
                                color: ThemeManager.accentColor
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                            
                            // 비디오 설정 항목들
                            Column {
                                width: parent.width
                                spacing: 16
                                
                                // 재생 속도
                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "Playback Speed"
                                        color: ThemeManager.textColor
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }
                                    
                                    ComboBox {
                                        model: ["0.25x", "0.5x", "0.75x", "1.0x", "1.25x", "1.5x", "2.0x"]
                                        currentIndex: 3  // 기본 1.0x
                                        
                                        onCurrentIndexChanged: {
                                            if (mpvObject) {
                                                var speedValues = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
                                                mpvObject.setProperty("speed", speedValues[currentIndex]);
                                            }
                                        }
                                    }
                                }
                                
                                // 하드웨어 가속
                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "Hardware Acceleration"
                                        color: ThemeManager.textColor
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }
                                    
                                    ComboBox {
                                        model: ["Auto", "Off"]
                                        
                                        onCurrentIndexChanged: {
                                            if (mpvObject) {
                                                var hwdecValues = ["auto-copy", "no"];
                                                mpvObject.setProperty("hwdec", hwdecValues[currentIndex]);
                                            }
                                        }
                                    }
                                }
                                
                                // 프레임 넘버링
                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "Frame Numbering"
                                        color: ThemeManager.textColor
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                    }
                                    
                                    ComboBox {
                                        model: ["0-based", "1-based"]
                                        
                                        onCurrentIndexChanged: {
                                            if (mpvObject) {
                                                mpvObject.oneBasedFrameNumbers = (currentIndex === 1);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 정보 탭
                Item {
                    id: aboutTab
                    
                    // 설정 목록을 스크롤 가능하게
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 16
                        clip: true
                        
                        // 스크롤바 스타일링
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: ThemeManager.scrollBarWidth
                            
                            background: Rectangle {
                                color: ThemeManager.scrollBarBgColor
                                radius: ThemeManager.scrollBarRadius
                            }
                            
                            contentItem: Rectangle {
                                implicitWidth: ThemeManager.scrollBarWidth
                                radius: ThemeManager.scrollBarRadius
                                color: parent.pressed ? ThemeManager.scrollBarActiveColor : 
                                       parent.hovered ? ThemeManager.scrollBarHoverColor : 
                                       ThemeManager.scrollBarColor
                            }
                        }
                        
                        Column {
                            width: parent.width
                            spacing: 20
                            
                            // 앱 로고 영역
                            Rectangle {
                                width: parent.width
                                height: 120
                                color: "transparent"
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "HYPER-PLAYER"
                                        font.pixelSize: 24
                                        font.weight: Font.Bold
                                        color: ThemeManager.accentColor
                                    }
                                    
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "v1.0"
                                        font.pixelSize: 16
                                        color: ThemeManager.secondaryTextColor
                                    }
                                    
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Professional Video Player"
                                        font.pixelSize: 14
                                        color: ThemeManager.textColor
                                    }
                                }
                            }
                            
                            // 구분선
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: ThemeManager.borderColor
                                opacity: 0.5
                            }
                            
                            // 정보 영역
                            Column {
                                width: parent.width
                                spacing: 15
                                
                                Text {
                                    width: parent.width
                                    text: "Built with MPV and Qt"
                                    color: ThemeManager.textColor
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Text {
                                    width: parent.width
                                    text: "© 2023 HyperMedia Team"
                                    color: ThemeManager.secondaryTextColor
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
            
            // 버튼 영역 (하단)
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: ThemeManager.tabBarColor
                
                Button {
                    id: okButton
                    text: "OK"
                    width: 100
                    height: 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 20
                    
                    background: Rectangle {
                        color: okButton.down ? ThemeManager.buttonPressedColor : 
                               okButton.hovered ? ThemeManager.buttonHoverColor : 
                               ThemeManager.buttonColor
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: okButton.text
                        color: ThemeManager.buttonTextColor
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        root.close()
                    }
                }
            }
        }
    }
}
