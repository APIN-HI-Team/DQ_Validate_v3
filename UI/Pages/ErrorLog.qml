import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../Components"
import QtQuick.Controls.Material

Pane {
    id: errorLogTable

    CustomMessageDialog {
        id: exportMessageBox
    }

    Rectangle {
        id: rectangle
        y: 0
        height: 50
        visible: true
        color: "#00000000"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 0

        CustomButton {
            id: backToLineListGenerationPage
            width: 64
            text: qsTr("back")
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20
            icon.height: 36
            icon.width: 36
            highlighted: true
            icon.color: "#ffffff"
            icon.source: "../Media/Icons/icons8-back-24.png"
            display: AbstractButton.IconOnly
            flat: true
            Material.background: theme.primaryColor
            onClicked: {

                stackLayout.currentIndex = 0
            }

            // Image {
            //     id: image
            //     width: 70
            //     height: 70
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.left: parent.left
            //     source: "../Media/Icons/icons8-back-24.png"
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     fillMode: Image.PreserveAspectFit
            // }
        }

        CustomButton {
            id: exportErrorsToCSV
            x: -49
            y: -35
            width: 100
            text: qsTr("Export")
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 0
            onClicked: {

                core.exportErrorsToExcel()
            }
        }
    }

    Rectangle {
        id: rectangle1
        color: "#ffffff"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: rectangle.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.topMargin: 5
        anchors.bottomMargin: 5

        ErrorLogTable {
            id: errorTable
            tableModel: core.errorModel
        }
    }
    Connections {
        target: core
        function onExportErrorLogSignal(message) {
            exportMessageBox.dialogTitle = "Success !!!"
            exportMessageBox.dialogMessage = message
            exportMessageBox.x = parent.width / 2
            exportMessageBox.open()
        }
    }
}
