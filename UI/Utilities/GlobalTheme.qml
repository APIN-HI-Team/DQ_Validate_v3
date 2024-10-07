import QtQuick 2.15

QtObject {
    id: theme

    property color primaryColor: "#007BFF" // Primary color (Windows blue)
    property color secondaryColor: "#28A745"
    property color accentColor: "#28A745" // Highlight positive or actionable items like call to action
    property color accentElementsColor: "#00A9F4" // Hover/Focus for interactive elements
    property color backgroundColor: "#f0f4f7" // Light background for contrast
    property color primaryTextColor: "#003366" // (Headings/Titles)
    property color secondaryTextColor: "#6C757D" // (subtitles/Descriptions)
    property color bodyTextColor: "#333333" // (Main Content)
    property color cardBorderColor: "#E0E0E0" // cards, containers, and input fields
    property color primaryBorderColor: "#A9B6EA"
}
