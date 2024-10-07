import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs
import QtQuick.Controls.Material
import "../utilities"

TextField {
    id: customTextEdit
    height: 30
    width: 200

    Material.primary: theme.primaryColor
    Material.accent: theme.accentColor

    property string placeholder: "Enter file path or click to select (Open/Save)"
    property int instanceId: -1
    placeholderText: placeholder
    readOnly: true

    MouseArea {
        anchors.fill: parent
        onClicked: fileDialog.open()
    }

    FileDialog {
        id: fileDialog
        title: "Select Linelist Script"
        nameFilters: ["SQL File (*.sql)"]

        onAccepted: {
            core.selectFile(fileDialog.selectedFile,
                            placeholder) // Call the Python method
        }
    }

    // Trigger when the QML component is fully loaded
    Component.onCompleted: {
        console.log("Component completed for placeholder: " + placeholder)
        core.initializeScriptPath(
                    placeholder) // Call Python function to initialize the text field

        var tableViewState = core.dataFrameModel

        globalState.saveComponentState("TaskFinished", taskfinished)
    }

    // Listen for updates from the backend and update the text field
    Connections {
        target: core
        function onSetScriptPath(label, value) {
            console.log("Setting script path: Label=" + label + ", Value=" + value)
            if (label === placeholder) {
                customTextEdit.text = value // Update the text field directly
            }
        }
    }
}
