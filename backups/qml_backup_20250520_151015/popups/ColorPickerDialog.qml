import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: colorPickerDialog
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Required properties
    property color controlBgColor
    property color borderColor
    property color textColor
    property string mainFont
    property string monoFont
    
    // Current selected color
    property color selectedColor: "black"
    
    width: 300
    height: 300
    
    signal colorSelected(color selectedColor)
    
    contentItem: Rectangle {
        implicitWidth: 300
        implicitHeight: 300
        color: controlBgColor
        border.color: borderColor
        border.width: 1
        
        // Title bar
        Rectangle {
            id: colorPickerTitleBar
            height: 24
            color: Qt.darker(controlBgColor, 1.1)
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            
            Text {
                text: "Color Picker"
                color: textColor
                font.pixelSize: 12
                font.family: mainFont
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
            }
            
            // Close button
            Rectangle {
                width: 20
                height: 20
                radius: 2
                color: "transparent"
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                
                Text {
                    text: "✕"
                    anchors.centerIn: parent
                    color: textColor
                    font.pixelSize: 12
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: colorPickerDialog.close()
                    hoverEnabled: true
                    onEntered: parent.color = Qt.rgba(1, 1, 1, 0.1)
                    onExited: parent.color = "transparent"
                }
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: colorPickerTitleBar.height + 6
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "black" // Color picker area
                border.color: borderColor
                border.width: 1
                
                // Color value will be filled here in a real color picker
            }
            
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 4
                columnSpacing: 10
                
                Text { text: "R:"; color: textColor; font.family: mainFont }
                Text { 
                    text: Math.round(selectedColor.r * 255)
                    color: textColor
                    font.family: monoFont 
                }
                
                Text { text: "G:"; color: textColor; font.family: mainFont }
                Text { 
                    text: Math.round(selectedColor.g * 255)
                    color: textColor
                    font.family: monoFont 
                }
                
                Text { text: "B:"; color: textColor; font.family: mainFont }
                Text { 
                    text: Math.round(selectedColor.b * 255)
                    color: textColor
                    font.family: monoFont 
                }
                
                Text { text: "A:"; color: textColor; font.family: mainFont }
                Text { 
                    text: selectedColor.a.toFixed(2)
                    color: textColor
                    font.family: monoFont 
                }
            }
        }
    }
} 