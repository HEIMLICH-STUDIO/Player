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
                        width: Math.max(100, implicitWidth)
                        
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
                    
                    // 타임라인 탭 (새로 추가)
                    TabButton {
                        height: 54
                        text: "Timeline"
                        width: Math.max(100, implicitWidth)
                        
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
                        width: Math.max(100, implicitWidth)
                        
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
                    
                    // 고급 설정 탭
                    TabButton {
                        height: 54
                        text: "Advanced"
                        width: Math.max(100, implicitWidth)
                        
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
                        width: Math.max(100, implicitWidth)
                        
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
                
                // 타임라인 설정 탭 (새로 추가)
                Item {
                    id: timelineTab
                    
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
                            
                            // 타임코드 설정 섹션
                            SettingsSection {
                                title: "Timecode Settings"
                                width: parent.width
                                
                                SettingsCard {
                                    title: "Timecode Format"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
                                        // 타임코드 형식 선택
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Timecode Format"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            ComboBox {
                                                id: timecodeFormatCombo
                                                model: [
                                                    "HH:MM:SS:FF (SMPTE Non-Drop)",
                                                    "HH:MM:SS;FF (SMPTE Drop-Frame)",
                                                    "HH:MM:SS.MS (Milliseconds)",
                                                    "Frames Only",
                                                    "Custom Format"
                                                ]
                                                
                                                onCurrentIndexChanged: {
                                                    if (mpvObject) {
                                                        // 타임코드 형식 저장
                                                        mpvObject.setProperty("user-timecode-format", currentIndex);
                                                        
                                                        // 커스텀 포맷 입력 필드 표시 여부
                                                        customFormatField.visible = (currentIndex === 4);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 커스텀 타임코드 형식 입력 필드
                                        RowLayout {
                                            id: customFormatField
                                            width: parent.width
                                            spacing: 10
                                            visible: timecodeFormatCombo.currentIndex === 4
                                            
                                            Text {
                                                text: "Custom Pattern"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            TextField {
                                                id: customFormatTextField
                                                placeholderText: "e.g. %H:%M:%S.%f"
                                                text: mpvObject ? mpvObject.getProperty("custom-timecode-pattern") || "%H:%M:%S.%f" : "%H:%M:%S.%f"
                                                
                                                onTextChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("custom-timecode-pattern", text);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 패턴 도움말 텍스트
                                        Text {
                                            visible: customFormatField.visible
                                            text: "Pattern tokens: %H (hour), %M (minute), %S (second), %f (frame), %t (total frames)"
                                            color: ThemeManager.secondaryTextColor
                                            font.pixelSize: 12
                                            wrapMode: Text.Wrap
                                            width: parent.width
                                        }
                                        
                                        // 내장 타임코드 사용 여부
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Use Embedded Timecode (if available)"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            Switch {
                                                id: useEmbeddedTimecodeSwitch
                                                checked: mpvObject ? mpvObject.getProperty("use-embedded-timecode") === "yes" : false
                                                
                                                onCheckedChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("use-embedded-timecode", checked ? "yes" : "no");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                SettingsCard {
                                    title: "Frame Numbering"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
                                        // 프레임 넘버링 기준
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
                                                id: frameNumberingCombo
                                                model: ["0-based", "1-based"]
                                                currentIndex: mpvObject && mpvObject.hasOwnProperty("oneBasedFrameNumbers") ? 
                                                              (mpvObject.oneBasedFrameNumbers ? 1 : 0) : 0
                                                
                                                onCurrentIndexChanged: {
                                                    if (mpvObject && mpvObject.hasOwnProperty("oneBasedFrameNumbers")) {
                                                        mpvObject.oneBasedFrameNumbers = (currentIndex === 1);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 타임코드 오프셋
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Timecode Offset (frames)"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            SpinBox {
                                                id: timecodeOffsetSpinBox
                                                from: -999
                                                to: 999
                                                value: mpvObject ? mpvObject.getProperty("timecode-offset") || 0 : 0
                                                
                                                onValueChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("timecode-offset", value);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // 고급 타임코드 설정 추가
                                SettingsCard {
                                    title: "Advanced Timecode Settings"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
                                        // 비디오 형식 기반 타임코드
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Video Standard"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            ComboBox {
                                                id: videoStandardCombo
                                                model: [
                                                    "Auto-detect", 
                                                    "Film (24 fps)",
                                                    "NTSC (29.97 fps)",
                                                    "PAL (25 fps)",
                                                    "Digital (30 fps)",
                                                    "High Frame Rate (60 fps)",
                                                    "Custom"
                                                ]
                                                
                                                onCurrentIndexChanged: {
                                                    if (mpvObject) {
                                                        // 커스텀 프레임 레이트 입력 필드 표시 여부
                                                        customFpsField.visible = (currentIndex === 6);
                                                        
                                                        // 각 비디오 표준에 맞는 프레임 레이트 설정
                                                        if (currentIndex < 6) {
                                                            var fpsValues = [0, 24, 29.97, 25, 30, 60]; // 0은 자동 감지
                                                            if (currentIndex > 0) { // 자동 감지가 아니면
                                                                mpvObject.setProperty("override-fps", fpsValues[currentIndex]);
                                                            }
                                                        }
                                                        
                                                        // NTSC인 경우 드롭 프레임 옵션 활성화
                                                        dropFrameOption.visible = (currentIndex === 2);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 커스텀 프레임 레이트 입력 필드
                                        RowLayout {
                                            id: customFpsField
                                            width: parent.width
                                            spacing: 10
                                            visible: videoStandardCombo.currentIndex === 6
                                            
                                            Text {
                                                text: "Custom Frame Rate"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            SpinBox {
                                                id: customFpsSpinBox
                                                from: 1
                                                to: 300
                                                value: 24
                                                stepSize: 1
                                                
                                                property real realValue: value
                                                
                                                // 소수점 지원
                                                validator: DoubleValidator {
                                                    bottom: 1
                                                    top: 300
                                                    decimals: 3
                                                    notation: DoubleValidator.StandardNotation
                                                }
                                                
                                                textFromValue: function(value) {
                                                    return Number(realValue).toFixed(3);
                                                }
                                                
                                                valueFromText: function(text) {
                                                    realValue = Number(text);
                                                    return Math.floor(realValue);
                                                }
                                                
                                                onRealValueChanged: {
                                                    if (mpvObject && visible) {
                                                        mpvObject.setProperty("override-fps", realValue);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // NTSC 드롭 프레임 옵션
                                        RowLayout {
                                            id: dropFrameOption
                                            width: parent.width
                                            spacing: 10
                                            visible: videoStandardCombo.currentIndex === 2
                                            
                                            Text {
                                                text: "Use Drop-Frame Timecode (NTSC)"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            Switch {
                                                id: useDropFrameSwitch
                                                checked: timecodeFormatCombo.currentIndex === 1
                                                
                                                onCheckedChanged: {
                                                    if (checked) {
                                                        timecodeFormatCombo.currentIndex = 1; // SMPTE Drop-Frame
                                                    } else {
                                                        timecodeFormatCombo.currentIndex = 0; // SMPTE Non-Drop
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 타임코드 소스 설정
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Timecode Source"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            ComboBox {
                                                id: timecodeSourceCombo
                                                model: [
                                                    "Calculate from Frames",
                                                    "Embedded SMPTE",
                                                    "File Metadata",
                                                    "Reel Name"
                                                ]
                                                
                                                onCurrentIndexChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("timecode-source", currentIndex);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 타임라인 외관 섹션
                            SettingsSection {
                                title: "Timeline Appearance"
                                width: parent.width
                                
                                SettingsCard {
                                    title: "Display Options"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
                                        // 타임라인에 프레임 눈금 표시
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Show Frame Ticks"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            Switch {
                                                id: showFrameTicksSwitch
                                                checked: true
                                                
                                                onCheckedChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("timeline-show-ticks", checked ? "yes" : "no");
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 큰 눈금 간격 설정
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Major Tick Interval (frames)"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                            }
                                            
                                            ComboBox {
                                                id: majorTickIntervalCombo
                                                model: ["5", "10", "24", "30", "60", "100", "Custom"]
                                                currentIndex: 2  // 기본값 24프레임
                                                
                                                onCurrentIndexChanged: {
                                                    if (currentIndex < 6) {  // "Custom" 아닌 경우
                                                        var intervalValues = [5, 10, 24, 30, 60, 100];
                                                        if (mpvObject) {
                                                            mpvObject.setProperty("timeline-major-tick", intervalValues[currentIndex]);
                                                        }
                                                        customTickSpinBox.visible = false;
                                                    } else {
                                                        customTickSpinBox.visible = true;
                                                    }
                                                }
                                            }
                                            
                                            SpinBox {
                                                id: customTickSpinBox
                                                visible: majorTickIntervalCombo.currentIndex === 6
                                                from: 1
                                                to: 1000
                                                value: 24
                                                
                                                onValueChanged: {
                                                    if (visible && mpvObject) {
                                                        mpvObject.setProperty("timeline-major-tick", value);
                                                    }
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
                
                // 고급 설정 탭
                Item {
                    id: advancedTab
                    
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
                            
                            // 성능 최적화 섹션
                            SettingsSection {
                                title: "Performance Optimization"
                                width: parent.width
                                
                                SettingsCard {
                                    title: "Caching Options"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
                                        // 캐시 초 설정
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Cache Seconds"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                                
                                                ToolTip.text: "Sets the maximum number of seconds to buffer. Higher values reduce stuttering on slow systems."
                                                ToolTip.visible: cacheMouseArea.containsMouse
                                                ToolTip.delay: 500
                                            }
                                            
                                            MouseArea {
                                                id: cacheMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                            }
                                            
                                            SpinBox {
                                                id: cacheSecsSpinBox
                                                from: 10
                                                to: 600
                                                value: mpvObject ? (mpvObject.getProperty("cache-secs") || 30) : 30
                                                stepSize: 10
                                                
                                                onValueChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("cache-secs", value);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 디먹서 미리 읽기 초 설정
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Demuxer Readahead Seconds"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                                
                                                ToolTip.text: "Determines how far ahead the demuxer reads. Higher values help with seeking performance."
                                                ToolTip.visible: readaheadMouseArea.containsMouse
                                                ToolTip.delay: 500
                                            }
                                            
                                            MouseArea {
                                                id: readaheadMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                            }
                                            
                                            SpinBox {
                                                id: demuxerReadaheadSpinBox
                                                from: 5
                                                to: 300
                                                value: mpvObject ? (mpvObject.getProperty("demuxer-readahead-secs") || 10) : 10
                                                stepSize: 5
                                                
                                                onValueChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("demuxer-readahead-secs", value);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                SettingsCard {
                                    title: "Seeking Options"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
                                        // 고정밀 탐색 옵션
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "High Precision Seeking"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                                
                                                ToolTip.text: "Controls seeking precision. 'Always' is most accurate but slowest, 'On Demand' is a good balance."
                                                ToolTip.visible: hrSeekMouseArea.containsMouse
                                                ToolTip.delay: 500
                                            }
                                            
                                            MouseArea {
                                                id: hrSeekMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                            }
                                            
                                            ComboBox {
                                                id: hrSeekComboBox
                                                model: ["Always", "On Demand", "Never"]
                                                
                                                Component.onCompleted: {
                                                    if (mpvObject) {
                                                        var hrSeekValue = mpvObject.getProperty("hr-seek");
                                                        if (hrSeekValue === "yes") {
                                                            currentIndex = 0;
                                                        } else if (hrSeekValue === "no") {
                                                            currentIndex = 2;
                                                        } else {
                                                            currentIndex = 1;
                                                        }
                                                    }
                                                }
                                                
                                                onCurrentIndexChanged: {
                                                    if (mpvObject) {
                                                        var hrSeekValues = ["yes", "default", "no"];
                                                        mpvObject.setProperty("hr-seek", hrSeekValues[currentIndex]);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 탐색 모드
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Seek Mode"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                                
                                                ToolTip.text: "Absolute seeks to exact position, Relative seeks from current position, Keyframes only jumps to keyframes (fastest)."
                                                ToolTip.visible: seekModeMouseArea.containsMouse
                                                ToolTip.delay: 500
                                            }
                                            
                                            MouseArea {
                                                id: seekModeMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                            }
                                            
                                            ComboBox {
                                                id: seekModeComboBox
                                                model: ["Absolute", "Relative", "Keyframes Only"]
                                                
                                                Component.onCompleted: {
                                                    if (mpvObject) {
                                                        var seekMode = mpvObject.getProperty("seek-mode");
                                                        if (seekMode === "absolute") {
                                                            currentIndex = 0;
                                                        } else if (seekMode === "relative") {
                                                            currentIndex = 1;
                                                        } else if (seekMode === "keyframes") {
                                                            currentIndex = 2;
                                                        }
                                                    }
                                                }
                                                
                                                onCurrentIndexChanged: {
                                                    if (mpvObject) {
                                                        var seekModeValues = ["absolute", "relative", "keyframes"];
                                                        mpvObject.setProperty("seek-mode", seekModeValues[currentIndex]);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                SettingsCard {
                                    title: "Memory & Buffer Settings"
                                    
                                    Column {
                                        width: parent.width
                                        spacing: 20
                                        
                                        // 캐시 크기 조절
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Cache Size (MB)"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                                
                                                ToolTip.text: "Sets the maximum memory used for caching. Higher values use more RAM but improve playback smoothness."
                                                ToolTip.visible: cacheSizeMouseArea.containsMouse
                                                ToolTip.delay: 500
                                            }
                                            
                                            MouseArea {
                                                id: cacheSizeMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                            }
                                            
                                            SpinBox {
                                                id: cacheSizeSpinBox
                                                from: 50
                                                to: 1024
                                                value: mpvObject ? (mpvObject.getProperty("demuxer-max-bytes") / (1024*1024) || 150) : 150
                                                stepSize: 50
                                                
                                                onValueChanged: {
                                                    if (mpvObject) {
                                                        // 값을 MB에서 바이트로 변환
                                                        mpvObject.setProperty("demuxer-max-bytes", value * 1024 * 1024);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 버퍼링 지속 시간 조절
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: "Initial Cache Duration (ms)"
                                                color: ThemeManager.textColor
                                                font.pixelSize: 14
                                                Layout.fillWidth: true
                                                
                                                ToolTip.text: "Wait this many milliseconds before starting playback. Increase for smoother start."
                                                ToolTip.visible: bufferingMouseArea.containsMouse
                                                ToolTip.delay: 500
                                            }
                                            
                                            MouseArea {
                                                id: bufferingMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                            }
                                            
                                            SpinBox {
                                                id: bufferingSpinBox
                                                from: 0
                                                to: 10000
                                                value: mpvObject ? (mpvObject.getProperty("cache-initial") || 0) : 0
                                                stepSize: 100
                                                
                                                onValueChanged: {
                                                    if (mpvObject) {
                                                        mpvObject.setProperty("cache-initial", value);
                                                    }
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
