import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material
import QtQuick.Layouts 2.15
import "../Components"

Pane {
    id: pane
    Material.background: Material.Indigo

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent

        Rectangle {
            id: errorLogContainer
            width: 200
            height: 200
            color: "#ffffff"
            Layout.fillHeight: true
            Layout.fillWidth: true

            ColumnLayout {
                id: columnLayout1
                anchors.fill: parent

                Rectangle {
                    id: errorLogHeader
                    width: 200
                    height: 50
                    color: "#ffffff"
                    Layout.fillWidth: true

                    Text {
                        id: _text
                        text: qsTr("ErrorLog")
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    CustomButton {
                        id: showErrorLog
                        x: -12
                        text: qsTr("Show Errors")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: customButton.left
                        anchors.rightMargin: 20

                        onClicked: {

                            customBusyIndicator.running = true
                            core.update_errorAggregateTable()
                            customBusyIndicator.running = false

                            stackLayout.currentIndex = 2
                        }
                    }

                    CustomButton {
                        id: customButton
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 36
                        width: 150

                        text: qsTr("Export Errors")

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

            IconImage {
                id: emptySectionImage
                x: 0
                y: 0
                opacity: 0.3
                anchors.fill: parent
                source: "../Media/Icons/table_view_48dp_005F73_FILL0_wght400_GRAD0_opsz48.svg"
                sourceSize.height: 300
                sourceSize.width: 300
                fillMode: Image.PreserveAspectFit
            }
        }
    }
}
