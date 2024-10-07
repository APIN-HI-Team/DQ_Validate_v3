import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material

Pane {
    id: pane
    Material.background: Material.Indigo

    Text {
        id: _text
        opacity: 0.6
        text: qsTr("Page 2")
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 40
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.styleName: "Bold"
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
