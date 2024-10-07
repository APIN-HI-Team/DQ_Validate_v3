import QtQuick
import QtQuick.Window
import QtQuick.Layouts 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material

import "./UI/Pages"
import "./UI/Components"
import "./UI/Utilities"
import "./UI/Fonts"

Window {
    id: window
    width: 1250
    height: 600
    visible: true
    visibility: Window.Maximized
    flags: Qt.Window

    title: qsTr("DQ Validate v3")
    Material.foreground: theme.primaryTextColor

    GlobalTheme {
        id: theme
    }

    // FontLoader {
    //     id: poppinsFont
    //     source: "/Fonts/Poppins/Poppins-Regular.ttf"
    // }
    Material.primary: theme.primaryColor
    Material.accent: theme.accentColor

    SplashScreen {
        id: splashScreen
        anchors.rightMargin: -1248
        anchors.topMargin: -598
        anchors.bottomMargin: -598
        anchors.horizontalCenter: mainContainer.horizontalCenter
        visible: true
        anchors.verticalCenter: mainContainer.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: mainContainer.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: -1248

        // Animation to fade out splash screen
        Behavior on opacity {
            OpacityAnimator {
                duration: 1000 // 1 second fade-out
                from: 1.0
                to: 0.0
            }
        }

        opacity: 1.0
    }
    function showSplashScreen(visible) {
        if (visible) {
            splashScreen.visible = true
            splashScreen.opacity = 1.0 // Show splash screen with full opacity
            mainContainer.visible = false // Ensure main content is hidden
            mainContainer.opacity = 0.0
        } else {
            splashScreen.opacity = 0.0 // Fade out the splash screen
            mainContainer.visible = true // Show main content
            mainContainer.opacity = 1.0 // Fade in main content
        }
    }

    Rectangle {
        id: mainContainer
        color: "#ffffff"
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        anchors.topMargin: 2
        anchors.bottomMargin: 2

        Rectangle {
            id: header
            height: 30
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: 0

            color: theme.secondaryColor

            Text {
                id: location
                text: core.location
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "Poppins Black"
                font.capitalization: Font.AllUppercase
                renderTypeQuality: Text.VeryHighRenderTypeQuality
                font.styleName: "Bold"
                font.bold: true
                color: "#ffffff"
            }
        }

        RoundButton {
            id: roundButton
            x: 1190
            y: 32
            text: ""
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.rightMargin: 20
            anchors.topMargin: 2
            flat: true
            bottomInset: 0
            rightInset: 0
            highlighted: false
            topInset: 0
            spacing: 0
            leftInset: 0
            padding: 0
            radius: (tabBar.height / 2) + 2

            contentItem: IconImage {
                anchors.verticalCenter: parent.verticalCenter
                source: "UI/Media/Icons/icons8-settings-48.png"
                sourceSize.height: 34
                sourceSize.width: 34
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
            }

            onClicked: {
                if (settingsDrawer.visible) {
                    settingsDrawer.close()
                    console.log("drawer close")
                } else {
                    settingsDrawer.open()
                    console.log("drawer open")
                }
            }
        }

        TabBar {
            id: tabBar
            x: 20
            y: 30
            width: 400
            anchors.left: parent.left
            anchors.top: header.bottom
            anchors.leftMargin: 20
            anchors.rightMargin: 0
            anchors.topMargin: 0

            CustomTabButton {
                id: tabButton
                text: qsTr("Generate LineList")
                font.pointSize: 12
                font.bold: true

                onClicked: stackLayout.currentIndex = 0
            }

            CustomTabButton {
                id: tabButton1
                text: qsTr("Database Management")
                font.pointSize: 12
                font.bold: true

                onClicked: stackLayout.currentIndex = 1
            }
        }
        StackLayout {
            id: stackLayout
            x: 0
            y: 78
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: tabBar.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 0

            LineListManagement {}
            DatabaseManagement {}
            ErrorLog {}
        }
    }

    Drawer {
        id: settingsDrawer
        edge: Qt.RightEdge
        width: 400
        margins: tabBar.height + header.height
        height: width
        visible: false
        dim: false
        modal: true
        focus: true

        Material.roundedScale: Material.NotRounded
        Material.elevation: 9

        Settings {
            anchors.fill: parent
        }
    }
}
