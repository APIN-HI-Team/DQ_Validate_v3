import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Imagine

Item {
    id: _item
    width: 800
    height: 600

    property var tableModel: null

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

            Keys.onPressed: {
                switch (event.key) {
                case Qt.Key_Down:
                    tableView.contentY += tableView.rowHeightProvider(0)
                    break
                case Qt.Key_Up:
                    tableView.contentY -= tableView.rowHeightProvider(0)
                    break
                case Qt.Key_Right:
                    tableView.contentX += tableView.columnWidthProvider(0)
                    break
                case Qt.Key_Left:
                    tableView.contentX -= tableView.columnWidthProvider(0)
                    break
                }
                event.accepted = true
            }

            columnWidthProvider: function (column) {
                return 250
            }
            rowHeightProvider: function (row) {
                return 30
            }

            model: tableModel

            delegate: Rectangle {
                width: tableView.columnWidthProvider(index.column)
                height: tableView.rowHeightProvider(index.row)
                color: selected ? 'lightblue' : 'white' // Highlight selected item
                border.width: 1
                border.color: 'gray'

                property bool selected: false

                Text {
                    text: model.display
                    anchors.fill: parent
                    anchors.margins: 10
                    color: 'black'
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: table.width
                contentHeight: table.height
                interactive: false // Prevent default scrolling

                property int cellHeight: 40
                property int cellWidth: 100

                onContentYChanged: {
                    // Snap contentY to the nearest row
                    flick.contentY = Math.round(
                                flick.contentY / flick.cellHeight) * flick.cellHeight
                }

                onContentXChanged: {
                    // Snap contentX to the nearest column
                    flick.contentX = Math.round(
                                flick.contentX / flick.cellWidth) * flick.cellWidth
                }

                // Use mouse wheel for scrolling through cells
                // onWheel: {
                //     flick.contentY += flick.cellHeight * (wheel.angleDelta.y > 0 ? -1 : 1)
                // }
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
        id: button
        width: 40
        height: 40
        text: qsTr("")
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 0
        anchors.topMargin: 0
        flat: true
        background: Rectangle {
            color: theme.primaryColor
        }
        // contentItem: IconImage {
        //     source: "../../build/exe.win-amd64-3.12/lib/bokeh/sampledata/_data/icons/chrome_32x32.png"
        // }
    }

    // Load the state when the component is completed
}
