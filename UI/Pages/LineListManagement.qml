import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material
import QtQuick.Layouts 2.15

import "../Components"

Pane {
    id: pane
    Material.background: theme.backgroundColor

    Column {
        id: column
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 20
        anchors.bottomMargin: 20
        z: 1
        spacing: 30

        CustomMessageDialog {
            id: messageBox
            dialogTitle: "Critical !!!"
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            z: 2
        }

        CustomPane {
            id: parametersPane
            height: parent.height * 0.3
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 0
            anchors.rightMargin: 0

            Row {
                id: row
                anchors.centerIn: parent

                anchors.left: parent.left
                anchors.leftMargin: 30
                spacing: 10

                DatePicker {
                    id: selectStartDate
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    placeholder: qsTr("Start Date")
                    instanceId: 1
                    onDateChanged: {
                        console.log(selectStartDate.date)
                        core.onDateChanged(selectStartDate, instanceId)
                    }
                }

                DatePicker {
                    id: selectEndDate
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    placeholder: qsTr("End Date")
                    instanceId: 2
                    onDateChanged: {
                        console.log(selectEndDate)
                        core.onDateChanged(selectEndDate.date, instanceId)
                    }
                }

                ComboBox {
                    id: selectLineListType
                    anchors.verticalCenter: parent.verticalCenter
                    width: 200
                    height: 40

                    model: ListModel {
                        id: lineListModel
                        ListElement {
                            text: "Select Linelist type"
                        }
                        ListElement {
                            text: "Patient Linelist"
                        }
                        ListElement {
                            text: "HTS Linelist"
                        }
                        ListElement {
                            text: "LIMS-EMR Linelist"
                        }
                    }

                    // Improved delegate handling
                    delegate: ItemDelegate {
                        id: comboBoxDelegate
                        width: parent.width
                        height: 40

                        Row {
                            anchors.fill: parent
                            Text {
                                text: model.text
                                font.italic: model.text === "Select Linelist type"
                                opacity: model.text === "Select Linelist type" ? 0.5 : 1.0
                                color: comboBoxDelegate.ListView.isCurrentItem ? theme.accentColor : "black"
                                font.bold: comboBoxDelegate.ListView.isCurrentItem
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selectLineListType.currentIndex = index
                                selectLineListType.popup.close(
                                            ) // Close dropdown on selection
                            }
                        }
                    }

                    // Handle selection changes directly
                    onCurrentIndexChanged: {
                        var selectedItem = lineListModel.get(currentIndex).text
                        if (selectedItem !== previousSelection
                                && selectedItem !== "Select Linelist type") {
                            core.getComBoBoxSelection(selectedItem)
                            previousSelection = selectedItem
                        }
                    }

                    property string previousSelection: ""
                }

                CustomButton {
                    id: generateLineList
                    text: qsTr("Generate LineList")
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: {
                        // Validate start and end dates
                        var startDateValid = selectStartDate.date !== "Start Date"
                                && selectStartDate.date !== ""
                        var endDateValid = selectEndDate.date !== "End Date"
                                && selectEndDate.date !== ""

                        // Validate linelist type
                        var linelistType = selectLineListType.currentText
                        var linelistTypeValid = linelistType !== "Select Linelist type"
                                && linelistType !== ""

                        // Check if linelist type is for "Patient Linelist" or something else
                        var isPatientLinelist = linelistType === "Patient Linelist"

                        // Perform actions based on validations
                        if (endDateValid && linelistTypeValid
                                && (isPatientLinelist || startDateValid)) {
                            customBusyIndicator.running = true
                            core.generate_linelist()
                        } else {
                            // Build list of missing parameters
                            var missingParams = []

                            if (!startDateValid) {
                                missingParams.push("Start Date")
                            }
                            if (!endDateValid) {
                                missingParams.push("End Date")
                            }
                            if (!linelistTypeValid) {
                                missingParams.push("Linelist Type")
                            }

                            var missingMsg = "Please set the following parameters: "
                                    + missingParams.join(", ")
                            console.log(missingMsg)
                            messageBox.dialogMessage = missingMsg
                            messageBox.open()
                        }
                    }
                }
            }
        }

        CustomPane {
            id: tableViewPane
            height: parent.height * 0.65
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: pane1.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 30

            ColumnLayout {
                id: columnLayout
                visible: false
                anchors.fill: parent

                Rectangle {
                    id: rectangle
                    width: 200
                    height: 50
                    color: "#ffffff"
                    Layout.fillWidth: true

                    CustomButton {
                        id: showErrorLog
                        x: -12
                        text: qsTr("Show Errors")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 22

                        onClicked: {
                            if (selectLineListType.currentText === "Patient Linelist") {
                                customBusyIndicator.running = true
                                core.update_errorAggregateTable()
                                customBusyIndicator.running = false

                                stackLayout.currentIndex = 2
                            } else {
                                messageBox.dialogTitle = "Critical !!!"
                                messageBox.dialogMessage
                                        = "Ony Patient LineList can be validated for now"
                                messageBox.open()
                            }
                        }
                    }

                    CustomButton {
                        id: exportToCSV
                        text: qsTr("Export to CSV")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: showErrorLog.left
                        anchors.rightMargin: 10

                        onClicked: core.exportToCSV()

                        Connections {
                            target: core
                            function onExportSuccessSignal(message) {
                                messageBox.dialogTitle = "Success !!!"
                                messageBox.dialogMessage = message
                                messageBox.open()
                            }
                        }
                    }
                }

                Rectangle {
                    id: tableViewContainer
                    width: 200
                    height: 200
                    color: "#ffffff"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    CustomTableView {
                        anchors.fill: parent
                        tableModel: core.dataFrameModel
                    }
                }
            }

            IconImage {
                id: emptySectionImage
                opacity: 0.3
                anchors.fill: parent
                source: "../Media/Icons/table_view_48dp_005F73_FILL0_wght400_GRAD0_opsz48.svg"
                sourceSize.height: 300
                sourceSize.width: 300
                fillMode: Image.PreserveAspectFit
            }

            CustomBusyIndicator {
                id: customBusyIndicator
                x: -94
                y: -80
                running: false
                z: 3
            }
        }
    }

    Connections {
        target: core
        function onTaskStarted() {
            customBusyIndicator.running = true
        }
        function onTaskFinished() {
            customBusyIndicator.running = false
            emptySectionImage.visible = false
            columnLayout.visible = true
        }
    }
}