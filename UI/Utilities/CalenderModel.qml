import QtQuick 2.15

QtObject {
    id: calenderModel

    // Signals for year, month, and day changes
    signal dateChanged

    // Centralized year, month, and day properties
    property int year: new Date().getFullYear()
    property int month: new Date().getMonth() + 1
    property int day: new Date().getDate()

    // Emit dateChanged signal when properties change
    onYearChanged: dateChanged()
    onMonthChanged: {
        dateChanged()
        updateDaysInMonth()
    }
    onDayChanged: dateChanged()

    // Binding for month name (updates automatically when month changes)
    property string monthName: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month - 1]
    property int firstDayOfWeek: (new Date(year, month - 1, 1).getDay(
                                      ) + 6) % 7 // Adjust so Monday is the first day

    // Binding to dynamically calculate days in the current month
    property var daysInMonthArray: []

    property int startYear: Math.floor((year - 1) / 10) * 10 - 1
    property int endYear: startYear + 11

    property var yearsInRange: generateYearsInRange()

    // Function to calculate if a year is a leap year
    function isLeapYear(year) {
        return (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0)
    }

    // Function to update the days of the current month
    function updateDaysInMonth() {
        var days = []
        var totalDaysInMonth = new Date(year, month, 0).getDate()
        var firstDay = firstDayOfWeek

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
        for (var i = 1; i <= totalDaysInMonth; i++) {
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

    // Function to change the month
    function changeMonth(offset) {
        month += offset
        if (month < 1) {
            month = 12
            year--
        } else if (month > 12) {
            month = 1
            year++
        }
        updateDaysInMonth() // Call once to recalculate the days
    }

    // Function to generate years in the current range
    function generateYearsInRange() {
        var years = []
        for (var y = startYear; y <= endYear; y++) {
            years.push({
                           "year": y.toString()
                       })
        }
        return years
    }

    // Function to change the year range
    function changeYear(offset) {
        if (offset > 0) {
            startYear = endYear - 1
            endYear = startYear + 11
        } else if (offset < 0) {
            endYear = startYear + 1
            startYear = endYear - 11
        }
        yearsInRange = generateYearsInRange()
    }

    Component.onCompleted: {
        updateDaysInMonth() // Initialize the days in the current month
    }
}
