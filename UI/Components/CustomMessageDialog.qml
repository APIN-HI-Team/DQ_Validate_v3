import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

Dialog {
    id: customDialog

    visible: false
    dim: false
    horizontalPadding: 0
    topPadding: 0
    verticalPadding: 0
    rightPadding: 0
    padding: 0
    leftPadding: 0

    modal: true

    // background: null
    width: 500
    height: 230

    Material.elevation: 6 // Adds shadow depth for Material design
    Material.roundedScale: Material.ExtraSmallScale
    // Dynamic properties
    property alias dialogTitle: na.text
    property string dialogMessage: "This is a custom Material Dialog."
    property color titleBackground: theme.primaryColor

    onAccepted: {
        console.log("Dialog accepted")
    }

    onRejected: {
        console.log("Dialog canceled")
    }

    Pane {
        id: pane
        anchors.fill: parent
        topInset: 0
        topPadding: 0
        verticalPadding: 0
        hoverEnabled: true
        horizontalPadding: 0
        bottomPadding: 0
        Material.elevation: 6

        Rectangle {
            id: messageType
            height: 30

            color: titleBackground
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 0
            Text {
                id: na
                // text: dialogTitle
                anchors.fill: parent
                anchors.leftMargin: 20
                verticalAlignment: Text.AlignVCenter
                font.pointSize: 12
                font.bold: true
                color: "#FFFFFF"
            }
        }

        Pane {
            id: messageContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: messageType.bottom
            anchors.bottom: buttonContainer.top
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 0
            anchors.bottomMargin: 0
            topPadding: 20
            rightPadding: 20
            leftPadding: 20
            bottomPadding: 0

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                spacing: 25

                IconImage {
                    id: imageIcon
                    width: 70

                    verticalAlignment: Image.AlignVCenter

                    source: {
                        if (customDialog.dialogTitle === "Critical !!!") {
                            return "../Media/Icons/icons8-error-48 (1).png"
                        } else if (customDialog.dialogTitle === "Warning !!!") {
                            return "../Media/Icons/icons8-error-48.png"
                        } else if (customDialog.dialogTitle === "Success !!!") {
                            return "../Media/Icons/icons8-success-48.png"
                        } else {
                            return "../Media/Icons/icons8-info-48.png" // Default icon if none match
                        }
                    }
                    Layout.fillHeight: true
                    sourceSize.height: 48
                    sourceSize.width: 48
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    id: messageText
                    text: customDialog.dialogMessage
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    fontSizeMode: Text.Fit
                    font.weight: Font.Medium
                    font.pointSize: 12
                    color: Material.foreground
                }
            }
        }

        Rectangle {
            id: buttonContainer
            height: 50
            color: "#ffffff"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 10

            // CustomNavigationButton {
            //     id: cancel
            //     buttonText: qsTr("Cancel")
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.right: ok.left
            //     anchors.rightMargin: 10
            //     Material.accent: "#FF5252" // Custom button color
            //     onClicked: customDialog.reject()
            // }
            CustomButton {
                id: ok
                width: 150
                text: qsTr("OK")

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 10
                anchors.topMargin: 0

                Material.accent: theme.accentColor
                // Material.roundedScale: Material.ExLargeScale
                onClicked: customDialog.accept()
            }
        }
    }
}
