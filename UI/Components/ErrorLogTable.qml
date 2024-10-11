import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Imagine

import "../utilities"
import "."

// import "../../images"
Item {
    id: _item
    anchors.fill: parent
    property var tableModel: null

    // Material.foreground: theme.bodyTextColor

    // ScrollView to handle table scrolling
    ScrollView {
        id: scrollView
        visible: true
        anchors.fill: parent
        anchors.topMargin: 40
        rightInset: 10
        layer.mipmap: true
        layer.enabled: true
        smooth: true
        activeFocusOnTab: true
        focus: true
        enabled: true
        clip: true
        hoverEnabled: true
        wheelEnabled: true

        // TableView to display the model data
        TableView {
            id: tableView
            anchors.left: verticalHeader.left
            anchors.fill: parent
            anchors.leftMargin: 40
            maximumFlickVelocity: 5000
            boundsMovement: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalAndVerticalFlick
            interactive: true

            property int fixedColumnWidth: 250 // Constant for fixed column width
            property int minFirstColumnWidth: 100 // Minimum width for the first column
            property int rowHeight: 25 // Constant row height

            columnWidthProvider: function (column) {
                if (column === 1 || column === 2) {
                    return fixedColumnWidth
                } else if (column === 0) {
                    // Calculate available space for the first column
                    const availableWidth = tableView.width - (2 * fixedColumnWidth)
                    return Math.max(availableWidth, minFirstColumnWidth)
                }
            }

            model: tableModel

            delegate: Item {
                width: tableView.columnWidthProvider(index.column)
                height: tableView.rowHeight

                // Background styling
                Rectangle {
                    id: backgroundRectangle
                    anchors.fill: parent
                    color: theme.backgroundColor
                    border.color: theme.primaryBorderColor
                    border.width: 1
                }

                // Use the function to set the image source
                IconImage {
                    id: backgroundImage
                    visible: true
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter

                    // source: "../../images/icons/icons8-eye-48.png"
                    sourceSize.height: 24
                    sourceSize.width: 24
                }
                function updateIcon() {
                    if (column === 2) {
                        return backgroundImage.source = "../Media/Icons/icons8-show-48.png"
                    } else {
                        return backgroundImage.source = ""
                    }
                }
                Component.onCompleted: {
                    updateIcon()
                }

                // Mouse interaction handling
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // Ensure the clicked cell is in column 3
                        if (column === 2) {
                            // Get the row index of the clicked cell
                            var rowIndex = row

                            var cellDataColumn1 = tableModel.data(
                                        tableView.index(rowIndex, 0),
                                        Qt.DisplayRole).toString()

                            core.openFilteredDF(cellDataColumn1)

                            errorDF.tableModel = core.errorDataFrameModel

                            // modal.dialogTitle = cellDataColumn1
                            modal.title = cellDataColumn1
                            modal.open()
                        }
                    }
                }

                // Display text within the cell
                Text {
                    anchors.centerIn: parent
                    text: model.display
                    color: theme.primaryTextColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
            }
        }
    }

    // HorizontalHeaderView for table column headers (Excel-like)
    HorizontalHeaderView {
        id: horizontalHeader
        height: 40
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 40
        resizableRows: true
        anchors.top: parent.top
        resizableColumns: true
        syncView: tableView
        clip: true
        interactive: true

        Repeater {
            model: tableModel.columnCount
            Rectangle {
                width: tableView.columnWidthProvider(index)
                height: horizontalHeader.height
                color: "#f0f0f0" // Light Excel-like header color
                border.color: "#c0c0c0" // Border for Excel-like effect
                border.width: 1

                Label {

                    text: tableModel.headerData(index, Qt.Horizontal)
                    elide: Text.ElideRight
                    anchors.fill: parent
                    color: '#000000'
                    font.pixelSize: 14
                    wrapMode: Text.WrapAnywhere
                    fontSizeMode: Text.HorizontalFit
                    font.family: "Poppins Black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SplitHCursor
                    onReleased: {
                        // Allow resizing like Excel
                        tableView.setColumnWidth(index,
                                                 tableView.columnWidthProvider(
                                                     index) + mouse.x)
                    }
                }
            }
        }
    }

    // VerticalHeaderView for row headers (index numbers)
    VerticalHeaderView {
        id: verticalHeader
        width: 40
        visible: true
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: horizontalHeader.bottom
        z: 1
        syncView: tableView
        clip: true

        Repeater {
            model: tableModel.rowCount
            Rectangle {
                width: verticalHeader.width
                height: tableView.rowHeightProvider(index)
                color: "#f0f0f0" // Light Excel-like header color
                border.color: "#c0c0c0" // Border for Excel-like effect
                border.width: 1

                property int rowNumber: index + 1 // Starting row number from 1

                Label {
                    anchors.centerIn: parent
                    text: rowNumber.toString() // Display row index (1-based)
                    color: '#000000'
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }
    }

    Button {
        id: button2
        width: 40
        height: 40
        text: qsTr("Button")
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 0
        anchors.topMargin: 0
    }

    CustomDialog {
        id: modal
        x: 27
        y: 27
        anchors.centerIn: parent
        width: parent.width * 0.7
        height: parent.height * 0.9
        rightPadding: 5
        leftPadding: 5

        CustomTableView {
            id: errorDF
            visible: true
            anchors.fill: parent
        }
    }
}
