import QtQuick 2.12
import RadialBar 1.0

RadialBar {
    id: bar
    implicitWidth: 96
    implicitHeight: implicitWidth
    foregroundColor: theme.controls.circleProgressBar.background
    progressColor: theme.controls.circleProgressBar.foreground
    dialWidth: theme.controls.circleProgressBar.thickness
    startAngle: 0
    spanAngle: 360

    from: 0
    to: 100
    value: 0

    showText: true
    textFont.pixelSize: theme ? theme.fontSize.big : 22
    textColor: theme ? theme.controls.circleProgressBar.text : "white"


    property alias from: bar.minValue
    property alias to: bar.maxValue
    property bool indeterminate: false

    property real indeterminateSpan:
        theme.controls.circleProgressBar.indeterminateSpan


    Binding {
        target: bar;
        property: "value";
        value: bar.to * bar.indeterminateSpan
        when: bar.indeterminate
    }

    Binding {
        target: bar
        property: "showText"
        value: false
        when: bar.indeterminate
    }

    RotationAnimator on rotation {
        running: bar.indeterminate
        from: 0
        to: 360
        loops: Animation.Infinite
        duration: theme ? (theme.animationDuration * 6) : 600
    }
}
