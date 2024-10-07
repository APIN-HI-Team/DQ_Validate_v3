import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../Components"

Pane {
    id: errorLogTable

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent

        Rectangle {
            id: rectangle
            width: 200
            height: 50
            color: "#ffffff"
            Layout.fillWidth: true

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
                text: qsTr("export")
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 0
                onClicked: {

                    core.exportErrorsToExcel()
                }
            }
        }

        ErrorLogTable {
            Layout.fillHeight: true
            Layout.fillWidth: true

            tableModel: core.errorModel
        }
    }
}
