import QtQuick 2.12
import QtQuick.Controls 2.12

MenuItem {
    id: menuItem
    spacing: theme.spacing
    leftPadding: spacing / 1.5
    rightPadding: spacing / 1.5
    topPadding: spacing / 2
    bottomPadding: spacing / 2


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
    }
}
