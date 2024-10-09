import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material

RoundButton {
    id: customBadge

    property alias var_count: customBadge.text

    Material.background: "Red"
    Material.foreground: "#FFFFFF"
}
