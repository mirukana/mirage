import QtQuick 2.12
import QtQuick.Controls 2.12

BusyIndicator {
    id: indicator
    implicitWidth: Math.min(192, Math.max(64, parent.width / 5))
    implicitHeight: 10

    contentItem: Item {
        Rectangle {
            id: rect
            width: indicator.height
            height: indicator.height
            radius: height / 2

            ColorAnimation on color {
                // Can't swap direct colors values
                property string c1: "white"
                property string c2: theme ? theme.colors.accentText : "cyan"

                id: colorAnimation
                from: c1
                to: c2
                duration: 1000
                onStopped: {[c1, c2] = [c2, c1]; start()}
            }

            XAnimator on x {
                from: 0
                to: indicator.width - rect.width
                duration: colorAnimation.duration / 2
                onStopped: {[from, to] = [to, from]; start()}
            }
        }
    }
}
