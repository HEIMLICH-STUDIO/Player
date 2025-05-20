import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Rectangle {
    id: testButtons
    color: "#202020"
    height: 40
    
    signal testAction1()
    signal testAction2()
    signal testAction3()
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 10
        
        TransparentButton {
            text: "Test 1"
            onClicked: testAction1()
        }
        
        TransparentButton {
            text: "Test 2"
            onClicked: testAction2()
        }
        
        TransparentButton {
            text: "Test 3"
            onClicked: testAction3()
        }
        
        Item { Layout.fillWidth: true }
    }
} 