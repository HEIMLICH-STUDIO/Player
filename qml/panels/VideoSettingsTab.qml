import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../utils"

ScrollView {
    id: videoSettingsTab
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    
    // Required property
    property var mpvPlayer
    
    ColumnLayout {
        width: parent.width
        spacing: 12
        
        GroupBox {
            title: qsTr("Color Adjustment")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: ThemeManager.isDarkTheme ? Qt.darker(ThemeManager.panelColor, 1.1) : Qt.lighter(ThemeManager.panelColor, 0.95)
                border.color: ThemeManager.borderColor
                border.width: 1
                radius: 4
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: ThemeManager.defaultFont
                font.pixelSize: ThemeManager.normalFontSize
                color: ThemeManager.textColor
                topPadding: 8
            }
            
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 10
                
                Text {
                    text: qsTr("Brightness:")
                    color: ThemeManager.textColor
                    font.family: ThemeManager.defaultFont
                }
                Slider {
                    id: brightnessSlider
                    from: -100
                    to: 100
                    value: 0
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        x: brightnessSlider.leftPadding
                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 3
                        width: brightnessSlider.availableWidth
                        height: implicitHeight
                        radius: 1.5
                        color: ThemeManager.borderColor
                        
                        Rectangle {
                            property real visualPos: 0.5 + (brightnessSlider.value / (brightnessSlider.to - brightnessSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: ThemeManager.accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: brightnessSlider.pressed ? ThemeManager.accentColorActive : ThemeManager.accentColor
                        border.color: ThemeManager.isDarkTheme ? "#FFFFFF" : "#FFFFFF"
                        border.width: 2
                    }
                    
                    onValueChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("brightness", value);
                        }
                    }
                }
                
                Text {
                    text: qsTr("Contrast:")
                    color: ThemeManager.textColor
                    font.family: ThemeManager.defaultFont
                }
                Slider {
                    id: contrastSlider
                    from: -100
                    to: 100
                    value: 0
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        x: contrastSlider.leftPadding
                        y: contrastSlider.topPadding + contrastSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 3
                        width: contrastSlider.availableWidth
                        height: implicitHeight
                        radius: 1.5
                        color: ThemeManager.borderColor
                        
                        Rectangle {
                            property real visualPos: 0.5 + (contrastSlider.value / (contrastSlider.to - contrastSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: ThemeManager.accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: contrastSlider.leftPadding + contrastSlider.visualPosition * (contrastSlider.availableWidth - width)
                        y: contrastSlider.topPadding + contrastSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: contrastSlider.pressed ? ThemeManager.accentColorActive : ThemeManager.accentColor
                        border.color: ThemeManager.isDarkTheme ? "#FFFFFF" : "#FFFFFF"
                        border.width: 2
                    }
                    
                    onValueChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("contrast", value);
                        }
                    }
                }
                
                Text {
                    text: qsTr("Saturation:")
                    color: ThemeManager.textColor
                    font.family: ThemeManager.defaultFont
                }
                Slider {
                    id: saturationSlider
                    from: -100
                    to: 100
                    value: 0
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        x: saturationSlider.leftPadding
                        y: saturationSlider.topPadding + saturationSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 3
                        width: saturationSlider.availableWidth
                        height: implicitHeight
                        radius: 1.5
                        color: ThemeManager.borderColor
                        
                        Rectangle {
                            property real visualPos: 0.5 + (saturationSlider.value / (saturationSlider.to - saturationSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: ThemeManager.accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: saturationSlider.leftPadding + saturationSlider.visualPosition * (saturationSlider.availableWidth - width)
                        y: saturationSlider.topPadding + saturationSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: saturationSlider.pressed ? ThemeManager.accentColorActive : ThemeManager.accentColor
                        border.color: ThemeManager.isDarkTheme ? "#FFFFFF" : "#FFFFFF"
                        border.width: 2
                    }
                    
                    onValueChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("saturation", value);
                        }
                    }
                }
                
                Text {
                    text: qsTr("Gamma:")
                    color: ThemeManager.textColor
                    font.family: ThemeManager.defaultFont
                }
                Slider {
                    id: gammaSlider
                    from: -100
                    to: 100
                    value: 0
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        x: gammaSlider.leftPadding
                        y: gammaSlider.topPadding + gammaSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 3
                        width: gammaSlider.availableWidth
                        height: implicitHeight
                        radius: 1.5
                        color: ThemeManager.borderColor
                        
                        Rectangle {
                            property real visualPos: 0.5 + (gammaSlider.value / (gammaSlider.to - gammaSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: ThemeManager.accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: gammaSlider.leftPadding + gammaSlider.visualPosition * (gammaSlider.availableWidth - width)
                        y: gammaSlider.topPadding + gammaSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: gammaSlider.pressed ? ThemeManager.accentColorActive : ThemeManager.accentColor
                        border.color: ThemeManager.isDarkTheme ? "#FFFFFF" : "#FFFFFF"
                        border.width: 2
                    }
                    
                    onValueChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("gamma", value);
                        }
                    }
                }
                
                Text {
                    text: qsTr("Hue:")
                    color: ThemeManager.textColor
                    font.family: ThemeManager.defaultFont
                }
                Slider {
                    id: hueSlider
                    from: -100
                    to: 100
                    value: 0
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        x: hueSlider.leftPadding
                        y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 3
                        width: hueSlider.availableWidth
                        height: implicitHeight
                        radius: 1.5
                        color: ThemeManager.borderColor
                        
                        Rectangle {
                            property real visualPos: 0.5 + (hueSlider.value / (hueSlider.to - hueSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: ThemeManager.accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: hueSlider.leftPadding + hueSlider.visualPosition * (hueSlider.availableWidth - width)
                        y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: hueSlider.pressed ? ThemeManager.accentColorActive : ThemeManager.accentColor
                        border.color: ThemeManager.isDarkTheme ? "#FFFFFF" : "#FFFFFF"
                        border.width: 2
                    }
                    
                    onValueChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("hue", value);
                        }
                    }
                }
                
                Button {
                    text: qsTr("Reset All")
                    Layout.columnSpan: 2
                    Layout.alignment: Qt.AlignHCenter
                    
                    onClicked: {
                        brightnessSlider.value = 0;
                        contrastSlider.value = 0;
                        saturationSlider.value = 0;
                        gammaSlider.value = 0;
                        hueSlider.value = 0;
                    }
                }
            }
        }
        
        GroupBox {
            title: qsTr("Video Processing")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: ThemeManager.isDarkTheme ? Qt.darker(ThemeManager.panelColor, 1.1) : Qt.lighter(ThemeManager.panelColor, 0.95)
                border.color: ThemeManager.borderColor
                border.width: 1
                radius: 4
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: ThemeManager.defaultFont
                font.pixelSize: ThemeManager.normalFontSize
                color: ThemeManager.textColor
                topPadding: 8
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                CheckBox {
                    id: deinterlaceCheck
                    text: qsTr("Deinterlace")
                    checked: false
                    
                    onCheckedChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("deinterlace", checked ? "yes" : "no");
                        }
                    }
                }
                
                CheckBox {
                    id: hwdecCheck
                    text: qsTr("Hardware Acceleration")
                    checked: true
                    
                    onCheckedChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("hwdec", checked ? "auto" : "no");
                        }
                    }
                }
                
                GroupBox {
                    title: qsTr("Scaling Method")
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        color: "transparent"
                        border.color: ThemeManager.borderColor
                        border.width: 1
                        radius: 4
                        y: parent.topPadding - parent.bottomPadding
                        width: parent.width
                        height: parent.height - parent.topPadding + parent.bottomPadding
                    }
                    
                    label: Label {
                        text: parent.title
                        font.bold: true
                        font.family: ThemeManager.defaultFont
                        font.pixelSize: ThemeManager.smallFontSize
                        color: ThemeManager.textColor
                        topPadding: 6
                    }
                    
                    ColumnLayout {
                        width: parent.width
                        
                        ComboBox {
                            id: scalingMethodCombo
                            Layout.fillWidth: true
                            model: [
                                "Bilinear (Fast)", 
                                "Bicubic (Quality)", 
                                "Spline36 (High Quality)", 
                                "Lanczos (Sharpest)"
                            ]
                            currentIndex: 1
                            
                            onCurrentIndexChanged: {
                                if (mpvPlayer) {
                                    var method = "";
                                    switch (currentIndex) {
                                        case 0: method = "bilinear"; break;
                                        case 1: method = "bicubic"; break;
                                        case 2: method = "spline36"; break;
                                        case 3: method = "lanczos"; break;
                                        default: method = "bicubic";
                                    }
                                    mpvPlayer.setProperty("scale", method);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Spacer
        Item {
            height: 10
            Layout.fillWidth: true
        }
    }
} 