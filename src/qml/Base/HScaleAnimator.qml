import QtQuick 2.12

ScaleAnimator {
    property real factor: 1.0
    property real overshoot: 1.0

    duration: theme.animationDuration * Math.max(overshoot / 1.7, 1.0) * factor
    easing.type: overshoot > 1 ? Easing.OutBack : Easing.Linear
    easing.overshoot: overshoot
}
