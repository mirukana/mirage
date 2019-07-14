// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Button {
    property bool circle: false

    property color backgroundColor: theme.controls.button.background
    property alias overlayOpacity: buttonBackgroundOverlay.opacity
    property bool checkedLightens: false

    signal canceled
    signal clicked
    signal doubleClicked
    signal entered
    signal exited
    signal pressAndHold
    signal pressed
    signal released

    id: button

    background: Rectangle {
        id: buttonBackground
        color: Qt.lighter(
            backgroundColor,
            ! enabled ? 0.7 :
            checked ? (checkedLightens ? 1.3 : 0.7) :
            1.0
        )
        radius: circle ? height : 0

        Behavior on color {
            ColorAnimation { duration: theme.animationDuration / 2 }
        }

        Rectangle {
            id: buttonBackgroundOverlay
            anchors.fill: parent
            radius: parent.radius
            color: "black"
            opacity: 0

            Behavior on opacity {
                HNumberAnimation { duration: theme.animationDuration / 2 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onCanceled: button.canceled()
        onClicked: button.clicked()
        onDoubleClicked: button.doubleClicked()
        onEntered: {
            overlayOpacity = checked ? 0 : 0.15
            button.entered()
        }
        onExited: {
            overlayOpacity = 0
            button.exited()
        }
        onPressAndHold: button.pressAndHold()
        onPressed: {
            overlayOpacity += 0.15
            button.pressed()
        }
        onReleased: {
            if (checkable) { checked = ! checked }
            overlayOpacity = checked ? 0 : 0.15
            button.released()
        }
    }
}
