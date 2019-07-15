// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

QtObject {
    id: theme

    property int animationDuration: 100

    property int minimumSupportedWidth: 240
    property int minimumSupportedHeight: 120

    property QtObject fontSize: QtObject {
        property int smallest: 6
        property int smaller: 8
        property int small: 13
        property int normal: 16
        property int big: 24
        property int bigger: 32
        property int biggest: 48
    }

    property QtObject fontFamily: QtObject {
        property string sans: "SFNS Display"
        property string serif: "Roboto Slab"
        property string mono: "Hack"
    }

    property int radius: 5

    property QtObject colors: QtObject {
        property color background0: Qt.hsla(0, 0, 0.9, 0.5)
        property color background1: Qt.hsla(0, 0, 0.9, 0.6)
        property color background2: Qt.hsla(0, 0, 0.9, 0.7)
        property color foreground: "black"
        property color foregroundDim: Qt.hsla(0, 0, 0.2, 1)
        property color foregroundDim2: Qt.hsla(0, 0, 0.3, 1)
        property color foregroundError: Qt.hsla(0.95, 0.64, 0.32, 1)
        property color textBorder: Qt.hsla(0, 0, 0, 0.07)
    }

    property QtObject controls: QtObject {
        property QtObject button: QtObject {
            property color background: colors.background2
        }

        property QtObject listEntry: QtObject {
            property color background: "transparent"
            property color hoveredBackground: Qt.hsla(0, 0, 0, 0.2)
            property color pressedBackground: Qt.hsla(0, 0, 0, 0.4)
            property color checkedBackground: Qt.hsla(0, 0, 0, 0.4)
        }

        property QtObject textField: QtObject {
            property color background: colors.background2
            property color borderColor: "black"
            property int borderWidth: 1
        }

        property QtObject textArea: QtObject {
            property color background: colors.background2
        }
    }

    property QtObject sidePane: QtObject {
        property color background: colors.background2

        property QtObject account: QtObject {
            property color background: Qt.lighter(colors.background2, 1.05)
        }

        property QtObject settingsButton: QtObject {
            property color background: colors.background2
        }

        property QtObject filterRooms: QtObject {
            property color background: colors.background2
        }
    }

    property QtObject chat: QtObject {
        property QtObject selectViewBar: QtObject {
            property color background: colors.background2
        }

        property QtObject roomHeader: QtObject {
            property color background: colors.background2
        }

        property QtObject eventList: QtObject {
            property color background: "transparent"
        }

        property QtObject message: QtObject {
            property color ownBackground: Qt.hsla(0.07, 0.4, 0.82, 0.7)
            property color background: colors.background2
            property color body: colors.foreground
            property color date: colors.foregroundDim
        }

        property QtObject daybreak: QtObject {
            property color background: colors.background2
            property color foreground: colors.foreground
            property int radius: theme.radius
        }

        property QtObject inviteBanner: QtObject {
            property color background: colors.background2
        }

        property QtObject leftBanner: QtObject {
            property color background: colors.background2
        }

        property QtObject unknownDevices: QtObject {
            property color background: colors.background2
        }

        property QtObject typingMembers: QtObject {
            property color background: colors.background1
        }

        property QtObject sendBox: QtObject {
            property color background: colors.background2
        }
    }

    property color pageHeadersBackground: colors.background2

    property QtObject box: QtObject {
        property color background: colors.background0
        property int radius: theme.radius
    }

    property QtObject avatar: QtObject {
        property int size: 36
        property int radius: theme.radius
        property color letter: "white"

        property QtObject background: QtObject {
            property real saturation: 0.22
            property real lightness: 0.5
            property real alpha: 1
            property color unknown: Qt.hsla(0, 0, 0.22, 1)
        }
    }

    property QtObject displayName: QtObject {
        property real saturation: 0.32
        property real lightness: 0.3
    }

    property int bottomElementsHeight: 36
}
