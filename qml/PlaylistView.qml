import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import MpvPlayer 1.0

Rectangle {
    id: root
    color: Theme.backgroundColor
    
    property MpvObject mpv
    property var playlist: []
    property int currentIndex: -1
    
    function addItem(filepath) {
        playlist.push(filepath)
        playlistModel.append({ path: filepath, name: getFileName(filepath) })
    }
    
    function getFileName(filepath) {
        return filepath.split('/').pop().split('\\').pop()
    }
    
    function playItem(index) {
        if (index >= 0 && index < playlist.length) {
            currentIndex = index
            mpv.filename = playlist[index]
            mpv.play()
        }
    }
    
    function playNext() {
        if (currentIndex < playlist.length - 1) {
            playItem(currentIndex + 1)
        }
    }
    
    function playPrevious() {
        if (currentIndex > 0) {
            playItem(currentIndex - 1)
        }
    }
    
    ListModel {
        id: playlistModel
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Theme.headerColor
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                
                Label {
                    text: qsTr("Playlist")
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.primaryTextColor
                }
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: qsTr("Add Files")
                    onClicked: {
                        // This would trigger a file dialog
                        // Implementation left for future enhancement
                    }
                    
                    background: Rectangle {
                        color: parent.hovered ? Theme.buttonHoverColor : Theme.buttonColor
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: Theme.primaryTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        ListView {
            id: playlistListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: playlistModel
            clip: true
            
            delegate: Rectangle {
                width: playlistListView.width
                height: 40
                color: index === currentIndex ? Theme.accentColor : (mouseArea.containsMouse ? Qt.darker(Theme.backgroundColor, 1.2) : "transparent")
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    
                    Label {
                        text: name
                        color: index === currentIndex ? "#FFFFFF" : Theme.primaryTextColor
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        playItem(index)
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                active: true
            }
        }
    }
} 