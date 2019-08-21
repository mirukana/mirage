import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Button {
    id: button
    spacing: theme.spacing
    leftPadding: spacing / 1.5
    rightPadding: spacing / 1.5
    topPadding: spacing / 2
    bottomPadding: spacing / 2
    iconItem.svgName: loading ? "hourglass" : icon.name

    onVisibleChanged: if (! visible) loading = false


    readonly property alias iconItem: contentItem.icon
    readonly property alias label: contentItem.label

    property color backgroundColor: theme.controls.button.background
    property bool loading: false
    property bool circle: false


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
