import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../utils"

Window {
    id: root
    title: qsTr("Scopes")
    width: 360
    height: 240
    color: ThemeManager.dialogColor
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
    visible: false

    property var mpvPlayer: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            CheckBox {
                id: histogramCheck
                text: qsTr("Histogram")
                contentItem: Text {
                    text: parent.text
                    color: ThemeManager.textColor
                }
                onCheckedChanged: root.updateFilters()
            }

            CheckBox {
                id: vectorscopeCheck
                text: qsTr("Vectorscope")
                contentItem: Text {
                    text: parent.text
                    color: ThemeManager.textColor
                }
                onCheckedChanged: root.updateFilters()
            }
        }
    }

    function updateFilters() {
        if (!mpvPlayer)
            return;

        var filters = [];
        if (histogramCheck.checked)
            filters.push("lavfi=histogram");
        if (vectorscopeCheck.checked)
            filters.push("lavfi=vectorscope");

        if (mpvPlayer.applyVideoFilters) {
            mpvPlayer.applyVideoFilters(filters);
        } else {
            mpvPlayer.command(["vf", "clr"]);
            for (var i = 0; i < filters.length; ++i)
                mpvPlayer.command(["vf", "add", filters[i]]);
        }
    }
}
