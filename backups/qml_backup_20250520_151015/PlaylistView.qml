import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: playlistView
    color: "#252525"
    
    property var playlistModel: []
    property int currentIndex: -1
    
    signal itemSelected(string filePath)
    
    ListView {
        id: list
        anchors.fill: parent
        model: playlistModel
        clip: true
        
        delegate: Rectangle {
            width: ListView.view.width
            height: 30
            color: index === currentIndex ? "#404040" : "transparent"
            
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                text: modelData.split('/').pop() // Display filename only
                color: "#FFFFFF"
                font.pixelSize: 12
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    currentIndex = index;
                    itemSelected(modelData);
                }
            }
        }
        
        ScrollBar.vertical: ScrollBar {
            active: true
        }
    }
} 