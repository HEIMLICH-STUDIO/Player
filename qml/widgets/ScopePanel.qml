import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../utils"

Rectangle {
    id: root
    width: 180
    color: ThemeManager.panelColor
    border.color: ThemeManager.borderColor
    border.width: 1
    radius: 4

    property var mpvPlayer: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Label {
            text: qsTr("Scopes")
            font.pixelSize: 14
            color: ThemeManager.textColor
            Layout.fillWidth: true
        }

        CheckBox {
            id: histogramCheck
            text: qsTr("Histogram")
            Layout.fillWidth: true
            contentItem: Text {
                text: parent.text
                color: ThemeManager.textColor
            }
            onCheckedChanged: root.updateFilters()
        }

        CheckBox {
            id: vectorscopeCheck
            text: qsTr("Vectorscope")
            Layout.fillWidth: true
            contentItem: Text {
                text: parent.text
                color: ThemeManager.textColor
            }
            onCheckedChanged: root.updateFilters()
        }
    }

    function updateFilters() {
        if (!mpvPlayer)
            return;
        mpvPlayer.command(["vf", "clr"]);
        if (histogramCheck.checked)
            mpvPlayer.command(["vf", "add", "lavfi=histogram"]);
        if (vectorscopeCheck.checked)
            mpvPlayer.command(["vf", "add", "lavfi=vectorscope"]);
    }
}
