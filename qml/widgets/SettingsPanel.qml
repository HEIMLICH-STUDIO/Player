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
    width: 520
    height: 580
    minimumWidth: 480
    minimumHeight: 520
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
        radius: 8
        
        // 메인 레이아웃
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0
            
            // 헤더 영역
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: ThemeManager.tabBarColor
                radius: 7
                // 상단만 둥글게
                Rectangle {
                    width: parent.width
                    height: parent.height / 2
                    anchors.bottom: parent.bottom
                    color: parent.color
                }
                
                TabBar {
                    id: tabBar
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    position: TabBar.Header
                    
                    background: Rectangle {
                        color: "transparent"
                    }
                    
                    // 일반 탭
                    TabButton {
                        height: 54
                        text: "General"
                        width: Math.max(120, implicitWidth)
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 15
                            font.weight: parent.checked ? Font.DemiBold : Font.Normal
                            color: parent.checked ? ThemeManager.accentColor : ThemeManager.tabButtonTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: "transparent"
                            
                            Rectangle {
                                width: parent.width
                                height: 3
                                anchors.bottom: parent.bottom
                                color: parent.parent.checked ? ThemeManager.accentColor : "transparent"
                                radius: 1.5
                            }
                        }
                    }
                    
                    // 비디오 탭
                    TabButton {
                        height: 54
                        text: "Video"
                        width: Math.max(120, implicitWidth)
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 15
                            font.weight: parent.checked ? Font.DemiBold : Font.Normal
                            color: parent.checked ? ThemeManager.accentColor : ThemeManager.tabButtonTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: "transparent"
                            
                            Rectangle {
                                width: parent.width
                                height: 3
                                anchors.bottom: parent.bottom
                                color: parent.parent.checked ? ThemeManager.accentColor : "transparent"
                                radius: 1.5
                            }
                        }
                    }
                    
                    // 정보 탭
                    TabButton {
                        height: 54
                        text: "About"
                        width: Math.max(120, implicitWidth)
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 15
                            font.weight: parent.checked ? Font.DemiBold : Font.Normal
                            color: parent.checked ? ThemeManager.accentColor : ThemeManager.tabButtonTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: "transparent"
                            
                            Rectangle {
                                width: parent.width
                                height: 3
                                anchors.bottom: parent.bottom
                                color: parent.parent.checked ? ThemeManager.accentColor : "transparent"
                                radius: 1.5
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
                        anchors.margins: 20
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
                            spacing: 24
                            
                            // 외형 설정 섹션
                            SettingsSection {
                                title: "Appearance"
                                width: parent.width
                                
                                SettingsCard {
                                    title: "Theme"
                                    
                                    RowLayout {
                                        width: parent.width
                                        spacing: 10
                                        
                                        Text {
                                            text: "Dark Mode"
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
                            }
                            
                            // 플레이백 설정 섹션
                            SettingsSection {
                                title: "Playback"
                                width: parent.width
                                
                                SettingsCard {
                                    title: "Playback Options"
                                    
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
                }
                
                // 비디오 설정 탭
                Item {
                    id: videoTab
                    
                    // 설정 목록을 스크롤 가능하게
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 20
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
                            spacing: 24
                            
                            // 비디오 설정 섹션
                            SettingsSection {
                                title: "Video Settings"
                                width: parent.width
                                
                                SettingsCard {
                                    title: "Performance"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
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
                                    }
                                }
                                
                                SettingsCard {
                                    title: "Display"
                                    
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
                }
                
                // 정보 탭
                Item {
                    id: aboutTab
                    
                    // 설정 목록을 스크롤 가능하게
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 20
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
                            spacing: 24
                            
                            // 앱 로고 영역
                            Rectangle {
                                width: parent.width
                                height: 160
                                radius: 8
                                color: ThemeManager.isDarkTheme ? Qt.rgba(0.12, 0.12, 0.12, 1.0) : Qt.rgba(0.97, 0.97, 0.97, 1.0)
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 16
                                    
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "HYPER-PLAYER"
                                        font.pixelSize: 28
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
                                        topPadding: 8
                                    }
                                }
                            }
                            
                            // 정보 카드
                            SettingsCard {
                                title: "Application Info"
                                
                                Column {
                                    width: parent.width
                                    spacing: 16
                                    
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
            }
            
            // 버튼 영역 (하단)
            Rectangle {
                Layout.fillWidth: true
                height: 72
                color: ThemeManager.tabBarColor
                
                // 하단만 둥글게
                radius: 7
                Rectangle {
                    width: parent.width
                    height: parent.height / 2
                    anchors.top: parent.top
                    color: parent.color
                }
                
                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 20
                    spacing: 12
                    
                    Button {
                        id: cancelButton
                        text: "Cancel"
                        width: 100
                        height: 40
                        
                        background: Rectangle {
                            color: cancelButton.down ? Qt.darker(ThemeManager.tabButtonColor, 1.1) : 
                                   cancelButton.hovered ? Qt.lighter(ThemeManager.tabButtonColor, 1.1) : 
                                   ThemeManager.tabButtonColor
                            radius: 6
                            border.width: 1
                            border.color: ThemeManager.borderColor
                        }
                        
                        contentItem: Text {
                            text: cancelButton.text
                            color: ThemeManager.textColor
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            root.close()
                        }
                    }
                    
                    Button {
                        id: okButton
                        text: "OK"
                        width: 100
                        height: 40
                        
                        background: Rectangle {
                            color: okButton.down ? ThemeManager.buttonPressedColor : 
                                   okButton.hovered ? ThemeManager.buttonHoverColor : 
                                   ThemeManager.buttonColor
                            radius: 6
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
    
    // 설정 섹션 컴포넌트
    component SettingsSection: Column {
        property string title: ""
        spacing: 16
        
        Text {
            text: title
            color: ThemeManager.accentColor
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }
    }
    
    // 설정 카드 컴포넌트
    component SettingsCard: Rectangle {
        property string title: ""
        width: parent.width
        height: contentColumn.height + 32
        radius: 8
        color: ThemeManager.isDarkTheme ? Qt.rgba(0.12, 0.12, 0.12, 1.0) : Qt.rgba(0.97, 0.97, 0.97, 1.0)
        border.width: 1
        border.color: ThemeManager.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.2, 1.0) : Qt.rgba(0.85, 0.85, 0.85, 1.0)
        
        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 16
            
            Text {
                visible: title !== ""
                text: title
                color: ThemeManager.secondaryTextColor
                font.pixelSize: 15
                font.weight: Font.Medium
            }
            
            default property alias content: container.data
            
            Item {
                id: container
                width: parent.width
                height: childrenRect.height
            }
        }
    }
}
