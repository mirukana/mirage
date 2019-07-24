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

            XAnimator on x {
                from: 0
                to: indicator.width - rect.width
                duration: 500
                onStopped: {[from, to] = [to, from]; start()}
            }
        }
    }
}
