// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Shapes 1.12


Item {
    property real progress: 0  // 0-1

    readonly property alias baseCircle: baseCircle
    readonly property alias progressCircle: progressCircle
    readonly property alias label: label


    implicitWidth: 96 * (theme ? theme.uiScale : 1)
    implicitHeight: implicitWidth

    layer.enabled: true
    layer.samples: 4
    layer.smooth: true

    HLabel {
        id: label

        property int progressNumber: Math.floor(progress * 100)

        anchors.centerIn: parent
        text: progressNumber + "%"
        font.pixelSize: theme ? theme.fontSize.big : 22

        Behavior on progressNumber { HNumberAnimation { factor: 2 } }
    }

    Shape {
        id: shape
        anchors.fill: parent
        asynchronous: true

        ShapePath {
            id: baseCircle
            fillColor: "transparent"
            strokeColor: theme.controls.circleProgressBar.background
            strokeWidth: theme.controls.circleProgressBar.thickness
            capStyle: ShapePath.RoundCap
            startX: shape.width / 2
            startY: strokeWidth

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                radiusX: shape.width / 2 - baseCircle.strokeWidth
                radiusY: shape.height / 2 - baseCircle.strokeWidth
                sweepAngle: 360
            }
        }

        ShapePath {
            id: progressCircle
            fillColor: baseCircle.fillColor
            strokeColor: theme.controls.circleProgressBar.foreground
            strokeWidth: baseCircle.strokeWidth

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                radiusX: shape.width / 2 - progressCircle.strokeWidth
                radiusY: shape.height / 2 - progressCircle.strokeWidth
                startAngle: 270
                sweepAngle: progress * 360

                Behavior on startAngle { HNumberAnimation {} }
                Behavior on sweepAngle { HNumberAnimation {} }
            }
        }
    }
}
