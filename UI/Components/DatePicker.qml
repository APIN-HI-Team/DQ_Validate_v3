import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Controls.Material

Item {
    id: customDateWidget

    implicitWidth: 200
    implicitHeight: 40

    property alias date: selectedDate.text
    property alias placeholder: selectedDate.placeholderText
    property int instanceId: -1

    // Custom signal to emit when the date changes
    signal customDateChanged(string newDate, int id)

    Rectangle {
        id: rectangle
        width: 200
        implicitHeight: 40
        color: "transparent"
        border.color: selectedDate.hasFocus ? Material.accent : theme.primaryBorderColor
        border.width: 1
        radius: 5

        // TextEdit for displaying and editing the selected date
        Rectangle {
            id: container

            anchors.fill: parent

            // TextField component
            TextField {
                id: selectedDate

                visible: true
                color: theme.accentColor
                Material.background: theme.backgroundColor
                anchors.left: parent.left
                anchors.right: calenderIcon.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                font.pixelSize: 12
                font.italic: true // Italic placeholder style
                verticalAlignment: TextEdit.AlignVCenter

                cursorVisible: true
                readOnly: false
                clip: false
                horizontalAlignment: TextEdit.AlignLeft

                // Material.containerStyle: Material.Outlined
                onFocusChanged: {
                    if (focus) {
                        calendarPopup.open() // Open the calendar popup on focus
                    }
                }

                // Detect keyboard interaction for editing
                Keys.onReturnPressed: {
                    if (text === "") {
                        text = "YYYY-MM-DD" // Reset if empty
                    }
                    clearFocus() // Optional: clear focus after entering text
                }
            }

            // Image component
            IconImage {
                id: calenderIcon
                source: "../Media/Icons/icons8-date-48.png"
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                sourceSize.height: 24
                sourceSize.width: 24

                fillMode: Image.PreserveAspectFit // Your image source here
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                anchors.right: parent.right
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        calendarPopup.open() // Open the calendar popup on click
                    }
                }
            }
        }
    }
    // // Popup for custom calendar
    Popup {
        id: calendarPopup
        width: 280
        height: 350
        dim: true
        verticalPadding: 0
        topPadding: 0
        horizontalPadding: 0
        clip: true
        x: (parent.width - width) / 2
        y: selectedDate.y + selectedDate.height

        background: null

        Pane {
            Material.elevation: 4
            anchors.fill: parent

            // Month Navigation Bar
            Rectangle {
                id: monthNavigation
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 60

                CustomButton {
                    id: leftCalenderDirectionButton1

                    contentItem: Text {

                        visible: true
                        text: qsTr("<")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.weight: Font.ExtraBold
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#ffffff"
                        font.bold: true
                    }

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 0
                    anchors.rightMargin: 5
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    font.styleName: "Bold"
                    font.pointSize: 12
                    font.bold: true
                    flat: true

                    width: 40
                    height: 40
                    anchors.left: parent.left
                    onClicked: calendarModel.changeMonth(-1)
                    Material.roundedScale: Material.ExtraSmallScale
                }

                Text {
                    id: monthYear
                    text: calendarModel.monthName + " " + calendarModel.year
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: monthYear.color = theme.accentColor
                        onExited: monthYear.color = "#000000"
                        onClicked: {
                            calendarPopup.close()
                            monthPickerPopup.open()
                        }
                    }
                }

                CustomButton {
                    id: rightCalenderDirectionButton1

                    contentItem: Text {

                        visible: true
                        text: qsTr(">")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.weight: Font.ExtraBold
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#ffffff"
                        font.bold: true
                    }

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 0
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    flat: true
                    width: 40
                    height: 40
                    visible: true
                    anchors.right: parent.right

                    Material.roundedScale: Material.ExtraSmallScale
                    onClicked: calendarModel.changeMonth(1)
                }
            }

            // Days of the Week Row
            GridLayout {
                id: daysOfWeek
                columns: 7
                rowSpacing: 5
                columnSpacing: 5
                anchors.top: monthNavigation.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    id: repeater
                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                    Pane {
                        width: 30
                        height: 15
                        contentHeight: 12
                        padding: 0
                        contentWidth: 30
                        verticalPadding: 0
                        topPadding: 12
                        rightPadding: 0
                        bottomPadding: 12
                        // Material.elevation: 2

                        // color: "transparent" // or set a background color if needed
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
                        }
                    }
                }
            }

            // Calendar Grid
            GridLayout {
                columns: 7
                rowSpacing: 5
                columnSpacing: 5
                anchors.top: daysOfWeek.bottom
                anchors.topMargin: 10
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: calendarModel.daysInMonthArray

                    Rectangle {
                        id: cMRect
                        width: 30
                        height: 30
                        // border.color: theme.borderColor
                        color: modelData.isNextMonth
                               || modelData.isPrevMonth ? "#e0e0e0" : "#ffffff"
                        radius: 5

                        Text {
                            id: dayText
                            text: modelData.day
                            anchors.centerIn: parent
                            color: modelData.color
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                parent.color = theme.accentColor
                                dayText.color = theme.textColor
                            }
                            onExited: {
                                parent.color = "transparent"
                                cMRect.color = modelData.isNextMonth
                                        || modelData.isPrevMonth ? "#e0e0e0" : "#ffffff"
                                dayText.color = modelData.color
                            }
                            onClicked: {
                                var day = modelData.day
                                var month = modelData.month
                                var year = modelData.year

                                if (modelData.isNextMonth) {
                                    month = (month % 12) + 1
                                    if (month === 1)
                                        year++
                                } else if (modelData.isPrevMonth) {
                                    month = (month - 1 + 12) % 12 + 1
                                    if (month === 12)
                                        year--
                                }

                                var formattedDay = day < 10 ? "0" + day : day
                                var formattedMonth = month < 10 ? "0" + month : month
                                selectedDate.text = year + "-" + formattedMonth + "-" + formattedDay
                                calendarPopup.close()
                                customDateWidget.customDateChanged(
                                            selectedDate.text,
                                            CustomDateControl.instanceId)
                            }
                        }
                    }
                }

                // Invisible spacer
                Repeater {
                    model: 7 - calendarModel.daysInMonthArray.length % 7

                    Rectangle {
                        width: 30
                        height: 30
                        color: "transparent"
                    }
                }
            }
        }
    }

    // Popup for month picker
    Popup {
        id: monthPickerPopup
        modal: true
        width: 280
        height: 350
        verticalPadding: 0
        topPadding: 0
        horizontalPadding: 0
        clip: true
        x: (parent.width - width) / 2
        y: selectedDate.y + selectedDate.height

        background: null
        Pane {
            Material.elevation: 6
            anchors.fill: parent

            // rightPadding: 35
            // leftPadding: 35
            Column {
                id: column
                anchors.fill: parent
                spacing: 10
                anchors.margins: 5
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                anchors.topMargin: 0
                anchors.bottomMargin: 0

                // Year selection row
                Rectangle {
                    id: row
                    height: 60
                    color: "#00000000"

                    radius: 5
                    border.color: theme.borderColor
                    border.width: 0
                    anchors.left: parent.left
                    anchors.right: parent.right // Fixed height
                    anchors.top: parent.top
                    anchors.leftMargin: 1
                    anchors.rightMargin: 1 // Anchored to the top
                    anchors.topMargin: 1
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter // Align center horizontally

                    Text {
                        id: yearName

                        text: calendarModel.year
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        anchors.bottomMargin: 0
                        font.pixelSize: 20
                        verticalAlignment: Text.AlignVCenter
                        anchors.horizontalCenter: parent.horizontalCenter

                        font.bold: true

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: yearName.color = theme.accentColor
                            onExited: yearName.color = "#000000"
                            onClicked: yearPopup.open()
                        }
                    }

                    CustomButton {
                        id: leftCalenderDirectionButton
                        width: 40

                        contentItem: Text {

                            visible: true
                            text: qsTr("<")
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.weight: Font.ExtraBold
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "#ffffff"
                            font.bold: true
                        }

                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 0
                        anchors.topMargin: 0
                        anchors.bottomMargin: 0
                        flat: true
                        height: 40
                        visible: true
                        anchors.left: parent.left

                        Material.roundedScale: Material.ExtraSmallScale
                        onClicked: calendarModel.year -= 1
                    }

                    CustomButton {
                        id: rightCalenderDirectionButton

                        contentItem: Text {

                            visible: true
                            text: qsTr(">")
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.weight: Font.ExtraBold
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "#ffffff"
                            font.bold: true
                        }

                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 5
                        anchors.topMargin: 0
                        anchors.bottomMargin: 0
                        font.styleName: "Bold"
                        font.pointSize: 12
                        font.bold: true
                        flat: true

                        width: 40
                        height: 40
                        onClicked: calendarModel.year += 1
                        Material.roundedScale: Material.ExtraSmallScale
                    }
                }

                // Month selection grid (centered vertically)
                Grid {
                    id: grid1
                    anchors.top: row.bottom
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 20
                    anchors.bottomMargin: 10
                    // anchors.leftMargin: 30
                    // anchors.rightMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 4
                    rowSpacing: 35

                    columnSpacing: 10
                    Layout.alignment: Qt.AlignCenter // Align center vertically

                    Repeater {
                        model: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

                        Rectangle {

                            width: 60
                            height: 60

                            // border.color: theme.borderColor
                            radius: 5 // Rounded corners for calendar days

                            Text {
                                id: monthText
                                text: modelData
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                font.pointSize: 10
                                font.bold: false
                                anchors.centerIn: parent
                                color: "#000000"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: {
                                    parent.color = theme.accentColor
                                    monthText.color = theme.textColor
                                }
                                onExited: {
                                    parent.color = "transparent"

                                    monthText.color = "#000000"
                                }

                                onClicked: {
                                    let monthIndex = index + 1
                                    calendarModel.month = monthIndex
                                    calendarModel.updateDaysInMonth()
                                    monthPickerPopup.close()
                                    calendarPopup.open(
                                                ) // Open the calendar popup
                                }
                            }
                        }
                    }
                }

                // Spacer for vertical centering
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Custom CalendarModel to handle date logic
    ListModel {
        id: calendarModel
        property int year: new Date().getFullYear()
        property int month: new Date().getMonth() + 1
        property string monthName: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month - 1]
        property int firstDayOfWeek: (new Date(year, month - 1, 1).getDay(
                                          ) + 6) % 7 // Adjust so Monday is the first day
        property var daysInMonthArray: []

        function updateDaysInMonth() {
            var days = []
            var date = new Date(year, month, 0).getDate(
                        ) // Number of days in the current month
            var lastDayOfWeek = (new Date(year, month, 0).getDay() + 6)
                    % 7 // Day of the week for the last day of the current month
            var firstDay = (new Date(year, month - 1, 1).getDay(
                                ) + 6) % 7 // Adjust so Monday is the first day

            // Add gray days from the previous month
            var prevMonthDays = new Date(year, month - 1, 0).getDate()
            var prevMonth = (month - 2 + 12) % 12 + 1
            var prevYear = month === 1 ? year - 1 : year
            for (var i = prevMonthDays - firstDay + 1; i <= prevMonthDays; i++) {
                days.push({
                              "day": i,
                              "color": "gray",
                              "isPrevMonth": true,
                              "isNextMonth": false,
                              "month": prevMonth,
                              "year": prevYear
                          })
            }

            // Add days for the current month
            for (var i = 1; i <= date; i++) {
                days.push({
                              "day": i,
                              "color": "black",
                              "isPrevMonth": false,
                              "isNextMonth": false,
                              "month": month,
                              "year": year
                          })
            }

            // Add gray days for the next month
            for (var i = 1; days.length % 7 !== 0; i++) {
                days.push({
                              "day": i,
                              "color": "gray",
                              "isPrevMonth": false,
                              "isNextMonth": true,
                              "month": (month % 12) + 1,
                              "year": month === 12 ? year + 1 : year
                          })
            }

            daysInMonthArray = days
        }

        Component.onCompleted: {
            updateDaysInMonth()
        }

        function changeMonth(offset) {
            month += offset
            if (month < 1) {
                month = 12
                year--
            } else if (month > 12) {
                month = 1
                year++
            }
            monthName = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month - 1]
            updateDaysInMonth()
        }
    }

    Popup {
        id: yearPopup
        width: 280
        height: 350
        dim: true
        verticalPadding: 0
        topPadding: 0
        horizontalPadding: 0
        clip: true
        x: (parent.width - width) / 2
        y: selectedDate.y + selectedDate.height

        background: null

        Pane {
            Material.elevation: 4
            anchors.fill: parent

            // Year Navigation Bar
            Rectangle {
                id: yearNavigation
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 60

                CustomButton {
                    id: leftYearDirectionButton
                    contentItem: Text {
                        visible: true
                        text: qsTr("<")
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#ffffff"
                        font.bold: true
                    }
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    onClicked: calendarModel2.changeYear(-10)
                    width: 40
                    flat: true
                }

                Text {
                    id: yearRange
                    text: calendarModel2.startYear + " - " + calendarModel2.endYear
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 18
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                CustomButton {
                    id: rightYearDirectionButton
                    contentItem: Text {
                        visible: true
                        text: qsTr(">")
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#ffffff"
                        font.bold: true
                    }
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    onClicked: calendarModel2.changeYear(10)
                    width: 40
                    flat: true
                }
            }

            // Year Grid
            GridLayout {
                id: yearGrid
                columns: 4
                rows: 3
                rowSpacing: 5
                columnSpacing: 5
                anchors.top: yearNavigation.bottom
                anchors.topMargin: 20
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: calendarModel2.yearsInRange

                    Rectangle {
                        width: 50
                        height: 50
                        color: modelData.year === calendarModel2.currentYear.toString(
                                   ) ? theme.accentColor : "#ffffff"
                        radius: 5

                        Text {
                            id: yearText
                            text: modelData.year
                            anchors.centerIn: parent
                            color: (modelData.year === calendarModel2.startYear.toString()
                                    || modelData.year === calendarModel2.endYear.toString(
                                        )) ? "gray" : (modelData.year
                                                       === calendarModel2.currentYear.toString(
                                                           ) ? "#ffffff" : "#000000")

                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                parent.color = theme.accentColor
                                yearText.color = "#ffffff"
                            }
                            onExited: {
                                parent.color = modelData.year
                                        === calendarModel2.currentYear.toString(
                                            ) ? theme.accentColor : "#ffffff"
                                yearText.color
                                        = (modelData.year === calendarModel2.startYear.toString()
                                           || modelData.year === calendarModel2.endYear.toString(
                                               )) ? "gray" : (modelData.year === calendarModel2.currentYear.toString(
                                                                  ) ? "#ffffff" : "#000000")
                            }
                            onClicked: {
                                // selectedDate.text = modelData.year
                                yearPopup.close()
                                monthPickerPopup.open()
                                // customDateWidget.customDateChanged(
                                //             selectedDate.text)
                            }
                        }
                    }
                }
            }
        }

        // Calendar Model
        QtObject {
            id: calendarModel2
            property int currentYear: new Date().getFullYear()
            property int startYear: Math.floor((currentYear - 1) / 10) * 10 - 1
            property int endYear: startYear + 11
            property var yearsInRange: generateYearsInRange()

            function generateYearsInRange() {
                var years = []
                for (var year = startYear; year <= endYear; year++) {
                    years.push({
                                   "year": year.toString()
                               })
                }
                return years
            }

            function changeYear(offset) {
                if (offset > 0) {
                    // Forward navigation
                    if (endYear) {
                        startYear = endYear - 1 // Set startYear to the current endYear - 1
                        endYear = startYear + 11 // Set endYear to maintain a 12-year range
                    }
                } else if (offset < 0) {
                    // Backward navigation
                    if (endYear) {
                        endYear = startYear + 1 // Set endYear to the previous start year
                        startYear = endYear - 11 // Subtract 11 to get the previous startYear
                    }
                }

                // Regenerate the years array based on the new startYear and endYear
                yearsInRange = generateYearsInRange()

                // Update yearRange text after changing year range
                yearRange.text = (startYear + 1) + " - " + (startYear + 10)
            }
        }
    }
}
