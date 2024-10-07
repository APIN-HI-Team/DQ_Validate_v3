import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material
import QtQuick.Layouts 2.15
import QtQuick.Dialogs
import "../Components"

Rectangle {
    id: settingsPage
    color: "#e4f1e7"

    Label {
        id: label
        height: 50
        text: qsTr("Settings")
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.topMargin: 1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pointSize: 20
        font.bold: true
    }

    Item {
        id: _item
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: label.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        anchors.topMargin: 30
        anchors.bottomMargin: 30

        CustomFileDialog {
            id: artScriptPath
            height: 30
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 0
            instanceId: 1
            placeholder: qsTr("ART LineList Script")
        }

        CustomFileDialog {
            id: htsScriptPath
            height: 30
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: artScriptPath.bottom
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 20
            instanceId: 2
            placeholder: qsTr("HTS LineList Script")
        }

        CustomFileDialog {
            id: lims_emrScriptPath
            height: 30
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: htsScriptPath.bottom
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 20
            instanceId: 3
            placeholder: qsTr("Lims-EMR Linelist Script")
        }
    }
    Component.onCompleted: {
        var art_ll_p = artScriptPath.placeholder
        var art_ll = artScriptPath.text

        var hts_ll_p = htsScriptPath.placeholder
        var hts_ll = htsScriptPath.text

        var lims_emr_ll_p = lims_emrScriptPath.placeholder
        var lims_emr_ll = lims_emrScriptPath.text

        globalState.saveComponentState("art_linelist_script", art_ll)
        globalState.saveComponentState("art_linelist_script", art_ll)
    }
}
