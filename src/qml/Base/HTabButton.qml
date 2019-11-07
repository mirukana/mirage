import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

TabButton {
    id: button
    spacing: theme.spacing
    topPadding: spacing / 1.5
    bottomPadding: topPadding
    leftPadding: spacing
    rightPadding: leftPadding

    iconItem.svgName: loading ? "hourglass" : icon.name
    icon.color: theme.icons.colorize
    enabled: ! loading

    // Must be explicitely set to display correctly on KDE
    implicitWidth: Math.max(
        implicitBackgroundWidth + leftInset + rightInset,
        // FIXME: why is *2 needed to not get ellided text in AddAccount page?
        implicitContentWidth + leftPadding * 2 + rightPadding * 2,
    )
    implicitHeight: Math.max(
        implicitBackgroundHeight + topInset + bottomInset,
        implicitContentHeight + topPadding + bottomPadding,
    )

    // Prevent button from gaining focus and being highlighted on click
    focusPolicy: Qt.TabFocus


    readonly property alias iconItem: contentItem.icon
    readonly property alias label: contentItem.label

    property color backgroundColor: theme.controls.tab.background
    property bool loading: false

    property HToolTip toolTip: HToolTip {
        id: toolTip
        visible: text && hovered
    }


    background: HButtonBackground {
        button: button
        buttonTheme: theme.controls.tab
        color: backgroundColor
    }

    contentItem: HButtonContent {
        id: contentItem
        button: button
        buttonTheme: theme.controls.tab
    }
}
