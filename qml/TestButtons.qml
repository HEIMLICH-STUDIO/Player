import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 800
    height: 600
    color: "#121212"
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        
        Text {
            text: "버튼 클릭 테스트"
            color: "white"
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }
        
        Button {
            text: "일반 버튼 테스트"
            Layout.preferredWidth: 200
            Layout.preferredHeight: 50
            Layout.alignment: Qt.AlignHCenter
            
            onClicked: function() {
                console.log("일반 버튼 클릭됨!")
                buttonStatus.text = "마지막 클릭: 일반 버튼 " + new Date().toLocaleTimeString()
            }
        }
        
        Rectangle {
            Layout.preferredWidth: 200
            Layout.preferredHeight: 50
            Layout.alignment: Qt.AlignHCenter
            color: "purple"
            
            Text {
                anchors.centerIn: parent
                text: "직접 구현 버튼"
                color: "white"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) {
                    console.log("직접 구현 버튼 클릭됨!")
                    buttonStatus.text = "마지막 클릭: 직접 구현 버튼 " + new Date().toLocaleTimeString()
                }
            }
        }
        
        Text {
            id: buttonStatus
            text: "아직 클릭 없음"
            color: "white"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
    }
} 