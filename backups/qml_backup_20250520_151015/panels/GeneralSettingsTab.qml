import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"

ScrollView {
    id: generalSettingsTab
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    
    // Required properties
    property color accentColor
    property color secondaryColor
    property color textColor
    property color panelColor
    property color controlBgColor
    property color darkControlColor
    property color borderColor
    property string mainFont
    property string monoFont
    property var mpvPlayer
    property real fps
    
    ColumnLayout {
        width: parent.width
        spacing: 12
        
        // 일반 설정 탭
        GroupBox {
            title: qsTr("Playback Info")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: Qt.rgba(0.12, 0.12, 0.12, 0.9)
                border.color: accentColor
                border.width: 1
                radius: 6
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
                
                // 그라데이션 효과 추가
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.14, 0.14, 0.17, 0.9) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.10, 0.10, 0.13, 0.9) }
                }
                
                // 섹션 라인
                Rectangle {
                    height: 2
                    width: parent.width - 20
                    color: accentColor
                    opacity: 0.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 32
                }
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: "Segoe UI"
                font.pixelSize: 14
                color: textColor
                topPadding: 8
                
                // 아이콘 추가
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.right
                    anchors.leftMargin: 8
                    spacing: 5
                    
                    Text {
                        text: "\uf1c8" // 비디오 아이콘 (FA 스타일)
                        font.family: "FontAwesome"
                        font.pixelSize: 14
                        color: secondaryColor
                    }
                }
            }
            
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 12
                rowSpacing: 8
                
                Text {
                    text: qsTr("Resolution:")
                    color: textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                }
                Text {
                    id: resolutionLabel
                    text: "1920 x 1080"
                    color: "#FFFFFF"
                    font.family: "Consolas"
                    font.pixelSize: 12
                }
                
                Text {
                    text: qsTr("FPS:")
                    color: textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                }
                Text {
                    text: fps.toFixed(3)
                    color: "#FFFFFF"
                    font.family: "Consolas"
                    font.pixelSize: 12
                }
                
                Text {
                    text: qsTr("Frames:")
                    color: textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                }
                Text {
                    id: framesLabel
                    text: mpvPlayer ? mpvPlayer.frameCount : "0"
                    color: "#FFFFFF"
                    font.family: "Consolas"
                    font.pixelSize: 12
                }
                
                Text {
                    text: qsTr("Codec:")
                    color: textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                }
                Text {
                    id: codecLabel
                    text: "H.264"
                    color: "#FFFFFF"
                    font.family: "Consolas"
                    font.pixelSize: 12
                }
                
                Text {
                    text: qsTr("Pixel Format:")
                    color: textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                }
                Text {
                    id: pixelFormatLabel
                    text: "YUV420P"
                    color: "#FFFFFF"
                    font.family: "Consolas"
                    font.pixelSize: 12
                }
            }
        }
        
        // 프레임 설정 섹션
        GroupBox {
            title: qsTr("Frame Settings")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: Qt.rgba(0.12, 0.12, 0.12, 0.9)
                border.color: secondaryColor
                border.width: 1
                radius: 6
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
                
                // 그라데이션 효과 추가
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.14, 0.14, 0.17, 0.9) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.10, 0.10, 0.13, 0.9) }
                }
                
                // 섹션 라인
                Rectangle {
                    height: 2
                    width: parent.width - 20
                    color: secondaryColor
                    opacity: 0.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 32
                }
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: "Segoe UI"
                font.pixelSize: 14
                color: textColor
                topPadding: 8
                
                // 아이콘 추가
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.right
                    anchors.leftMargin: 8
                    spacing: 5
                    
                    Text {
                        text: "\uf51f" // 프레임 아이콘 (FA 스타일)
                        font.family: "FontAwesome"
                        font.pixelSize: 14
                        color: secondaryColor
                    }
                }
            }
            
            ColumnLayout {
                width: parent.width
                spacing: 10
                
                // 프레임 번호 시작 방식
                Text {
                    text: qsTr("Frame Numbering")
                    color: textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    font.bold: true
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    RadioButton {
                        id: zeroBasedBtn
                        text: qsTr("Zero-based (0 to N-1)")
                        checked: mpvPlayer ? !mpvPlayer.oneBasedFrameNumbers : true
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            color: textColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing
                        }
                        
                        onCheckedChanged: {
                            if (checked && mpvPlayer) {
                                mpvPlayer.oneBasedFrameNumbers = false;
                            }
                        }
                    }
                    
                    RadioButton {
                        id: oneBasedBtn
                        text: qsTr("One-based (1 to N)")
                        checked: mpvPlayer ? mpvPlayer.oneBasedFrameNumbers : false
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            color: textColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing
                        }
                        
                        onCheckedChanged: {
                            if (checked && mpvPlayer) {
                                mpvPlayer.oneBasedFrameNumbers = true;
                            }
                        }
                    }
                }
                        
                // 프레임 번호 설명
                Rectangle {
                    Layout.fillWidth: true
                    height: infoText.implicitHeight + 16
                    color: Qt.rgba(0.1, 0.1, 0.1, 0.7)
                    radius: 4
                    
                    Text {
                        id: infoText
                        anchors.fill: parent
                        anchors.margins: 8
                        text: qsTr("Zero-based numbering starts from 0, while one-based starts from 1. Choose based on your workflow preference.")
                        color: "#CCCCCC"
                        font.pixelSize: 11
                        font.family: "Segoe UI"
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
        
        // 재생 속도 컨트롤 - 향상된 디자인
        GroupBox {
            title: qsTr("Playback Speed")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: Qt.rgba(0.12, 0.12, 0.12, 0.9)
                border.color: accentColor
                border.width: 1
                radius: 6
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
                
                // 그라데이션 효과 추가
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.14, 0.14, 0.17, 0.9) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.10, 0.10, 0.13, 0.9) }
                }
                
                // 섹션 라인
                Rectangle {
                    height: 2
                    width: parent.width - 20
                    color: accentColor
                    opacity: 0.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 32
                }
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: "Segoe UI"
                font.pixelSize: 14
                color: textColor
                topPadding: 8
                
                // 아이콘 추가
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.right
                    anchors.leftMargin: 8
                    spacing: 5
                    
                    Text {
                        text: "\uf04b" // 플레이 아이콘 (FA 스타일)
                        font.family: "FontAwesome"
                        font.pixelSize: 14
                        color: accentColor
                    }
                }
            }
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Slider {
                    id: speedSlider
                    from: 0.25
                    to: 4.0
                    value: 1.0
                    stepSize: 0.25
                    Layout.fillWidth: true
                    
                    Component.onCompleted: {
                        if (mpvPlayer) {
                            // 초기 속도를 설정할 때는 명령 하나만 사용
                            try {
                                mpvPlayer.command(["set_property", "speed", value]);
                            } catch (e) {
                                console.error("Speed setting error:", e);
                            }
                        }
                    }
                    
                    background: Rectangle {
                        x: speedSlider.leftPadding
                        y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: speedSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#444444"
                        
                        Rectangle {
                            width: speedSlider.visualPosition * parent.width
                            height: parent.height
                            color: secondaryColor
                            radius: 2
                        }
                    }
                    
                    handle: Rectangle {
                        x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                        y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: speedSlider.pressed ? Qt.darker(secondaryColor, 1.2) : secondaryColor
                        border.color: "#FFFFFF"
                        border.width: 2
                    }
                    
                    onValueChanged: {
                        if (mpvPlayer) {
                            try {
                                // 속도 설정은 한 번만 수행 (과도한 명령 방지)
                                mpvPlayer.setProperty("speed", value);
                            } catch (e) {
                                console.error("Speed change error:", e);
                            }
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: speedSlider.value.toFixed(2) + "x"
                        color: textColor
                        font.family: "Consolas"
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                            
                    // 프리셋 버튼들
                    Row {
                        spacing: 4
                        
                        Repeater {
                            model: [0.5, 1.0, 1.5, 2.0]
                            
                            Button {
                                width: 36
                                height: 24
                                text: modelData + "x"
                                
                                background: Rectangle {
                                    radius: 4
                                    color: speedSlider.value === modelData ? 
                                           accentColor : Qt.rgba(0.2, 0.2, 0.2, 0.8)
                                    border.color: speedSlider.value === modelData ? 
                                                  "white" : Qt.rgba(0.3, 0.3, 0.3, 0.8)
                                    border.width: 1
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: "Segoe UI"
                                    color: speedSlider.value === modelData ? 
                                           "white" : "#CCCCCC"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                onClicked: {
                                    speedSlider.value = modelData;
                                }
                            }
                        }
                    }
                    
                    TransparentButton {
                        text: qsTr("Reset")
                        textColorNormal: "#FFFFFF"
                        textColorHover: accentColor
                        onClicked: {
                            speedSlider.value = 1.0;
                        }
                    }
                }
            }
        }
        
        // 룹 재생 설정 - 향상된 디자인
        GroupBox {
            title: qsTr("Playback Options")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: Qt.rgba(0.12, 0.12, 0.12, 0.9)
                border.color: secondaryColor
                border.width: 1
                radius: 6
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
                
                // 그라데이션 효과 추가
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.14, 0.14, 0.17, 0.9) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.10, 0.10, 0.13, 0.9) }
                }
                
                // 섹션 라인
                Rectangle {
                    height: 2
                    width: parent.width - 20
                    color: secondaryColor
                    opacity: 0.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 32
                }
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: "Segoe UI"
                font.pixelSize: 14
                color: textColor
                topPadding: 8
                
                // 아이콘 추가
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.right
                    anchors.leftMargin: 8
                    spacing: 5
                    
                    Text {
                        text: "\uf1de" // 설정 아이콘 (FA 스타일)
                        font.family: "FontAwesome"
                        font.pixelSize: 14
                        color: secondaryColor
                    }
                }
            }
            
            ColumnLayout {
                width: parent.width
                spacing: 10
                
                CheckBox {
                    text: qsTr("Loop Playback")
                    checked: false
                    Layout.fillWidth: true
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.family: "Segoe UI"
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: parent.indicator.width + parent.spacing
                    }
                    
                    onCheckedChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.loop = checked;
                        }
                    }
                }
                
                CheckBox {
                    text: qsTr("Auto-Pause at Last Frame")
                    checked: true
                    Layout.fillWidth: true
                    enabled: false // 항상 활성화됨
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.family: "Segoe UI"
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: parent.indicator.width + parent.spacing
                    }
                }
                
                CheckBox {
                    id: autoPlayCheck
                    text: qsTr("Auto-Play on Load")
                    checked: false
                    Layout.fillWidth: true
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.family: "Segoe UI"
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: parent.indicator.width + parent.spacing
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
} 