import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material

Dialog {
    id: customDialog

    Material.background: theme.backgroundColor
    Material.foreground: theme.primaryTextColor
    Material.roundedScale: Material.SmallScale
}
