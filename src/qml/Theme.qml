// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import "utils.js" as Ut

QtObject {
    id: theme

    property int minimumSupportedWidth: 240
    property int minimumSupportedHeight: 120
    property int contentIsWideAbove: 439

    property int minimumSupportedWidthPlusSpacing: 240 + spacing * 2
    property int minimumSupportedHeightPlusSpacing: 120 + spacing * 2

    property int baseElementsHeight: 36
    property int spacing: 8
    property int animationDuration: 100

    property QtObject fontSize: QtObject {
        property int smallest: 6
        property int smaller: 8
        property int small: 13
        property int normal: 16
        property int big: 22
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
        property color background0: Ut.hsla(0, 0, 90, 0.5)
        property color background1: Ut.hsla(0, 0, 90, 0.6)
        property color background2: Ut.hsla(0, 0, 90, 0.7)
        property color foreground: "black"
        property color foregroundDim: Ut.hsl(0, 0, 20)
        property color foregroundDim2: Ut.hsl(0, 0, 30)
        property color foregroundError: Ut.hsl(342, 64, 32)
        property color textBorder: Ut.hsla(0, 0, 0, 0.07)
        property color accent: Ut.hsl(25, 60, 50)
        property color accentDarker: Ut.hsl(25, 60, 35)
    }

    property QtObject controls: QtObject {
        property QtObject button: QtObject {
            property color background: colors.background2
        }

        property QtObject interactiveRectangle: QtObject {
            property color background: "transparent"
            property color hoveredBackground: Ut.hsla(0, 0, 0, 0.2)
            property color pressedBackground: Ut.hsla(0, 0, 0, 0.4)
            property color checkedBackground: Ut.hsla(0, 0, 0, 0.4)
        }

        property QtObject textField: QtObject {
            property color background: colors.background2
            property color border: "transparent"
            property color focusedBackground: background
            property color focusedBorder: colors.accent
            property int borderWidth: 1
        }

        property QtObject textArea: QtObject {
            property color background: colors.background2
        }
    }

    property QtObject sidePane: QtObject {
        property real autoWidthRatio: 0.33
        property int maximumAutoWidth: 320

        property int autoCollapseBelowWidth: 128
        property int collapsedWidth: avatar.size

        property int autoReduceBelowWindowWidth:
            minimumSupportedWidthPlusSpacing + collapsedWidth

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
            property int ownEventsOnRightUnderWidth: 768
            property color background: "transparent"
        }

        property QtObject message: QtObject {
            property color ownBackground: Ut.hsla(25, 40, 82, 0.7)
            property color background: colors.background2
            property color body: colors.foreground
            property color date: colors.foregroundDim

            property color link: colors.accentDarker
            // property color code: Ut.hsl(0, 0, 80)
            // property color codeBackground: Ut.hsl(0, 0, 10)
            property color code: Ut.hsl(265, 60, 35)
            property color greenText: Ut.hsl(80, 60, 25)

            property string styleSheet:
                "a { color: " + link  + " }" +

                "code { font-family: " + fontFamily.mono + "; " +
                       "color: "       + code            + " }" +

                "h1, h2 { font-weight: normal }" +
                "h6 { font-size: small }" +

                ".greentext { color: " + greenText + " }"

            property string styleInclude:
                '<style type"text/css">\n' + styleSheet + '\n</style>\n'
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
        property int size: baseElementsHeight
        property int radius: theme.radius
        property color letter: "white"

        property QtObject background: QtObject {
            property real saturation: 0.22
            property real lightness: 0.5
            property real alpha: 1
            property color unknown: Ut.hsl(0, 0, 22)
        }
    }

    property QtObject displayName: QtObject {
        property real saturation: 0.32
        property real lightness: 0.3
    }
}
