import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: videoSettingsTab
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    
    // Required properties
    property color accentColor
    property color secondaryColor
    property color textColor
    property color panelColor
    property color controlBgColor
    property color borderColor
    property var mpvPlayer
    
    ColumnLayout {
        width: parent.width
        spacing: 12
        
        GroupBox {
            title: qsTr("Color Adjustment")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: Qt.darker(panelColor, 1.1)
                border.color: borderColor
                border.width: 1
                radius: 4
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: "Segoe UI"
                font.pixelSize: 13
                color: textColor
                topPadding: 8
            }
            
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 10
                
                Text {
                    text: qsTr("Brightness:")
                    color: textColor
                    font.family: "Segoe UI"
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
                        color: "#444444"
                        
                        Rectangle {
                            property real visualPos: 0.5 + (brightnessSlider.value / (brightnessSlider.to - brightnessSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: brightnessSlider.pressed ? Qt.darker(accentColor, 1.1) : accentColor
                        border.color: "#FFFFFF"
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
                    color: textColor
                    font.family: "Segoe UI"
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
                        color: "#444444"
                        
                        Rectangle {
                            property real visualPos: 0.5 + (contrastSlider.value / (contrastSlider.to - contrastSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: contrastSlider.leftPadding + contrastSlider.visualPosition * (contrastSlider.availableWidth - width)
                        y: contrastSlider.topPadding + contrastSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: contrastSlider.pressed ? Qt.darker(accentColor, 1.1) : accentColor
                        border.color: "#FFFFFF"
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
                    color: textColor
                    font.family: "Segoe UI"
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
                        color: "#444444"
                        
                        Rectangle {
                            property real visualPos: 0.5 + (saturationSlider.value / (saturationSlider.to - saturationSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: saturationSlider.leftPadding + saturationSlider.visualPosition * (saturationSlider.availableWidth - width)
                        y: saturationSlider.topPadding + saturationSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: saturationSlider.pressed ? Qt.darker(accentColor, 1.1) : accentColor
                        border.color: "#FFFFFF"
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
                    color: textColor
                    font.family: "Segoe UI"
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
                        color: "#444444"
                        
                        Rectangle {
                            property real visualPos: 0.5 + (gammaSlider.value / (gammaSlider.to - gammaSlider.from)) * 0.5
                            width: visualPos * parent.width
                            height: parent.height
                            color: accentColor
                            radius: 1.5
                        }
                    }
                    
                    handle: Rectangle {
                        x: gammaSlider.leftPadding + gammaSlider.visualPosition * (gammaSlider.availableWidth - width)
                        y: gammaSlider.topPadding + gammaSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: gammaSlider.pressed ? Qt.darker(accentColor, 1.1) : accentColor
                        border.color: "#FFFFFF"
                        border.width: 2
                    }
                    
                    onValueChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("gamma", value);
                        }
                    }
                }
                
                Button {
                    text: qsTr("Reset")
                    Layout.columnSpan: 2
                    Layout.alignment: Qt.AlignHCenter
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 12
                        font.family: "Segoe UI"
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        radius: 4
                        color: parent.down ? Qt.darker("#444444", 1.2) : 
                              parent.hovered ? Qt.lighter("#444444", 1.1) : "#444444"
                    }
                    
                    onClicked: {
                        brightnessSlider.value = 0;
                        contrastSlider.value = 0;
                        saturationSlider.value = 0;
                        gammaSlider.value = 0;
                    }
                }
            }
        }
        
        // Video rendering settings
        GroupBox {
            title: qsTr("Rendering Settings")
            Layout.fillWidth: true
            
            background: Rectangle {
                color: Qt.darker(panelColor, 1.1)
                border.color: borderColor
                border.width: 1
                radius: 4
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
            }
            
            label: Label {
                text: parent.title
                font.bold: true
                font.family: "Segoe UI"
                font.pixelSize: 13
                color: textColor
                topPadding: 8
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                
                Text {
                    text: qsTr("Scaling Algorithm:")
                    color: textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                }
                
                ComboBox {
                    id: scalingCombo
                    model: ["Bilinear", "Spline", "Lanczos", "Bicubic"]
                    Layout.fillWidth: true
                    
                    delegate: ItemDelegate {
                        width: scalingCombo.width
                        contentItem: Text {
                            text: modelData
                            color: textColor
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        highlighted: scalingCombo.highlightedIndex === index
                        
                        background: Rectangle {
                            color: highlighted ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "transparent"
                        }
                    }
                    
                    indicator: Canvas {
                        id: canvas
                        x: scalingCombo.width - width - 5
                        y: scalingCombo.height / 2 - height / 2
                        width: 12
                        height: 8
                        contextType: "2d"
                        
                        onPaint: {
                            context.reset();
                            context.moveTo(0, 0);
                            context.lineTo(width, 0);
                            context.lineTo(width / 2, height);
                            context.closePath();
                            context.fillStyle = accentColor;
                            context.fill();
                        }
                    }
                    
                    contentItem: Text {
                        leftPadding: 8
                        rightPadding: scalingCombo.indicator.width + 8
                        
                        text: scalingCombo.displayText
                        font: scalingCombo.font
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    
                    background: Rectangle {
                        implicitWidth: 120
                        implicitHeight: 30
                        border.color: scalingCombo.pressed ? accentColor : borderColor
                        border.width: scalingCombo.visualFocus ? 2 : 1
                        radius: 4
                        color: scalingCombo.pressed ? Qt.darker(controlBgColor, 1.1) : controlBgColor
                    }
                    
                    popup: Popup {
                        y: scalingCombo.height - 1
                        width: scalingCombo.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 1
                        
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: scalingCombo.popup.visible ? scalingCombo.delegateModel : null
                            currentIndex: scalingCombo.highlightedIndex
                            
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }
                        
                        background: Rectangle {
                            border.color: borderColor
                            border.width: 1
                            radius: 4
                            color: panelColor
                        }
                    }
                    
                    onCurrentTextChanged: {
                        if (mpvPlayer) {
                            mpvPlayer.setProperty("scale", currentText.toLowerCase());
                        }
                    }
                }
                
                // Add spacing
                Item { height: 8; Layout.fillWidth: true }
                
                CheckBox {
                    text: qsTr("Use Hardware Acceleration")
                    checked: true
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.family: "Segoe UI"
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: parent.indicator.width + parent.spacing
                    }
                    
                    onCheckedChanged: {
                        if (mpvPlayer && !checked) {
                            mpvPlayer.setProperty("hwdec", "no");
                        } else if (mpvPlayer) {
                            mpvPlayer.setProperty("hwdec", "auto");
                        }
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
} 