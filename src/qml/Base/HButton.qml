import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Button {
    id: button
    spacing: theme.spacing
    leftPadding: spacing / 1.5
    rightPadding: leftPadding
    topPadding: spacing / 2
    bottomPadding: topPadding
    iconItem.svgName: loading ? "hourglass" : icon.name
    icon.color: theme.icons.colorize
    enabled: ! loading


    readonly property alias iconItem: contentItem.icon
    readonly property alias label: contentItem.label

    property color backgroundColor: theme.controls.button.background
    property bool loading: false
    property bool circle: false

    property HToolTip toolTip: HToolTip {
        id: toolTip
        visible: text && hovered
    }


    background: HButtonBackground {
        button: button
        buttonTheme: theme.controls.button
        radius: circle ? height : 0
        color: backgroundColor
    }

    contentItem: HButtonContent {
        id: contentItem
        button: button
        buttonTheme: theme.controls.button
    }
}
