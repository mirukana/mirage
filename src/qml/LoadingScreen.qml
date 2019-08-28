import QtQuick 2.12
import "Base"

Item {
    Rectangle {
        anchors.fill: parent
        scale: Math.max(
            1.6, Math.ceil(parent.parent.width / parent.parent.height)
        )
        rotation: 45 * 3
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.hsla(0.73, 0.25, 0.25, 1) }
            GradientStop { position: 1.0; color: Qt.hsla(0.52, 1, 0.06, 1) }
        }
    }

    HBusyIndicator {
        anchors.centerIn: parent
        width: Math.min(160, parent.width - 16, parent.height - 16)
        height: width
    }
}
