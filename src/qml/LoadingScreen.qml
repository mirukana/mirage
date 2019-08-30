import QtQuick 2.12
import "Base"

Item {
    Rectangle {
        anchors.fill: parent
        scale: Math.max(
            2.25, Math.ceil(parent.parent.width / parent.parent.height)
        )
        rotation: -45
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#001b20" }
            GradientStop { position: 1.0; color: "#3c2f4b" }
        }
    }

    HBusyIndicator {
        anchors.centerIn: parent
        width: Math.min(160, parent.width - 16, parent.height - 16)
        height: width
    }
}
