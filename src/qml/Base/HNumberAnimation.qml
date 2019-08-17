import QtQuick 2.12

NumberAnimation {
    property real factor: Math.max(overshoot / 1.75, 1.0)
    property real overshoot: 1.0

    duration: theme.animationDuration * factor
    easing.type: overshoot > 1 ? Easing.InOutBack : Easing.Linear
    easing.overshoot: overshoot
}
