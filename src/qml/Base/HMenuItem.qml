import QtQuick 2.12
import QtQuick.Controls 2.12

MenuItem {
    id: menuItem
    spacing: theme.spacing
    leftPadding: spacing
    rightPadding: spacing
    topPadding: spacing / 1.75
    bottomPadding: spacing / 1.75
    height: visible ? implicitHeight : 0


    readonly property alias iconItem: contentItem.icon
    readonly property alias label: contentItem.label


    background: HButtonBackground {
        button: menuItem
        buttonTheme: theme.controls.menuItem
    }

    contentItem: HButtonContent {
        id: contentItem
        button: menuItem
        buttonTheme: theme.controls.menuItem
        label.horizontalAlignment: Label.AlignLeft
    }
}
