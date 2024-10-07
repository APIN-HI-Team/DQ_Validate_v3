import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material

Rectangle {
    id: splashScreen
    width: 640
    height: 480
    color: "white"
    visible: true // Ensure this is set to make the splash screen visible

    Material.accent: "#FFFFFF"

    Image {
        id: splashLogo
        anchors.fill: parent
        source: "../Media/Images/rm373batch15-bg-11.jpg"
        anchors.horizontalCenter: parent.horizontalCenter
        // Replace with the actual path to your logo
        fillMode: Image.Stretch
    }

    Text {
        text: "Loading, please wait..."
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        font.pixelSize: 20
        color: "#FFFFFF"
    }

    BusyIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        running: true
    }
}
