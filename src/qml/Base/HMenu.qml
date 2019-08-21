import QtQuick 2.12
import QtQuick.Controls 2.12

Menu {
    id: menu
    padding: theme.controls.menu.borderWidth

    implicitWidth: {
        let result       = 0
        let leftPadding  = 0
        let rightPadding = 0

        for (let i = 0; i < count; ++i) {
            let item     = itemAt(i)
            result       = Math.max(item.contentItem.implicitWidth, result)
            leftPadding  = Math.max(item.leftPadding, leftPadding)
            rightPadding = Math.max(item.rightPadding, rightPadding)
        }
        return Math.min(
            result + leftPadding + rightPadding, window.width
        )
    }

    background: HRectangle {
        color: "transparent"
        border.color: theme.controls.menu.border
        border.width: theme.controls.menu.borderWidth
    }
}
