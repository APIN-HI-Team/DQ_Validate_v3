import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material

BusyIndicator {
    id: busyIndicator
    y: -182
    width: 100
    height: 100
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    z: 3
    running: false
}
