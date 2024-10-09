import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../Components"

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
            x: -9
            y: -35
            width: 40
            text: qsTr("back")
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 0
            flat: true
            onClicked: {

                stackLayout.currentIndex = 0
            }
        }

        CustomButton {
            id: exportErrorsToCSV
            x: -49
            y: -35
            width: 40
            text: qsTr("Export Errors")
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
            exportMessageBox.open()
        }
    }
}
