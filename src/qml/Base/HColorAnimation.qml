import QtQuick 2.12

ColorAnimation {
    property real factor: 1.0
    duration: theme.animationDuration * factor
}
