import QtQuick 2.12
import QtGraphicalEffects 1.12
import "Base"

Item {
    LinearGradient {
        anchors.fill: parent
        start: Qt.point(0, 0)
        end: Qt.point(window.width, window.height)

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#001b20" }
            GradientStop { position: 1.0; color: "#3c2f4b" }
        }
    }

    HBusyIndicator {
        anchors.centerIn: parent
        width: Math.min(160, parent.width - 16, parent.height - 16)
        height: width
        indeterminateSpan: 0.5

        foregroundColor: Qt.hsla(0, 0, 1, 0.15)
        progressColor: Qt.hsla(0, 0, 1, 0.4)
    }
}
