import QtQuick 2.12
import QtQuick.Controls 2.12

ToolTip {
    id: toolTip
    delay: theme.controls.toolTip.delay
    padding: background.border.width
    contentWidth: Math.min(
        mainUI.width / 1.25,
        contentItem.implicitWidth,
        theme.fontSize.normal * 0.5 * 75,
    )

    background: Rectangle {
        id: background
        color: theme.controls.toolTip.background
        border.color: theme.controls.toolTip.border
        border.width: theme.controls.toolTip.borderWidth
    }

    contentItem: HLabel {
        color: theme.controls.toolTip.text
        text: toolTip.text
        wrapMode: Text.Wrap
        property var pr: width

        leftPadding: theme.spacing / 1.5
        rightPadding: leftPadding
        topPadding: theme.spacing / 2
        bottomPadding: topPadding
    }

    enter: Transition {
        HNumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }
    exit: Transition {
        HNumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
    }

    TapHandler {
        onTapped: { toolTip.hide() }
    }

    HoverHandler {
        onHoveredChanged: if (! hovered) toolTip.hide()
    }
}
