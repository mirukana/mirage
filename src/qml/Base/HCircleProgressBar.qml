import QtQuick 2.12
import RadialBar 1.0

RadialBar {
    id: bar
    foregroundColor: theme.controls.circleProgressBar.background
    progressColor: theme.controls.circleProgressBar.foreground
    dialWidth: theme.controls.circleProgressBar.thickness
    startAngle: 0
    spanAngle: 360

    from: 0
    to: 100
    value: 0

    showText: true
    suffixText: qsTr("%")
    textFont.pixelSize: theme.fontSize.big
    textColor: theme.controls.circleProgressBar.text


    property alias from: bar.minValue
    property alias to: bar.maxValue
    property bool indeterminate: false


    Binding {
        target: bar;
        property: "value";
        value: bar.to * theme.controls.circleProgressBar.indeterminateSpan
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
