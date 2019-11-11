import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Button {
    id: button
    spacing: theme.spacing
    topPadding: spacing / (circle ? 1.75 : 1.5)
    bottomPadding: topPadding
    leftPadding: spacing / (circle ? 1.5 : 1)
    rightPadding: leftPadding

    iconItem.svgName: loading ? "hourglass" : icon.name
    icon.color: theme.icons.colorize

    // Must be explicitely set to display correctly on KDE
    implicitWidth: Math.max(
        implicitBackgroundWidth + leftInset + rightInset,
        implicitContentWidth + leftPadding + rightPadding
    )
    implicitHeight: Math.max(
        implicitBackgroundHeight + topInset + bottomInset,
        implicitContentHeight + topPadding + bottomPadding
    )

    // Prevent button from gaining focus and being highlighted on click
    focusPolicy: Qt.TabFocus


    readonly property alias iconItem: contentItem.icon
    readonly property alias label: contentItem.label

    property color backgroundColor: theme.controls.button.background
    property bool disableWhileLoading: true
    property bool loading: false
    property bool circle: false

    property HToolTip toolTip: HToolTip {
        id: toolTip
        visible: text && hovered
    }


    Binding {
        when: disableWhileLoading && loading
        target: button
        property: "enabled"
        value: false
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
