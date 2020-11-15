// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

Rectangle {
    property string presence

    implicitWidth:
        window.settings.General.compact ?
        theme.controls.presence.radius * 2 :
        theme.controls.presence.radius * 2.5

    implicitHeight: width
    radius: width / 2
    opacity:
        theme.controls.presence.opacity * (presence.includes("echo") ? 0.5 : 1)

    color:
        presence.includes("online") ?
        theme.controls.presence.online :

        presence.includes("unavailable") ?
        theme.controls.presence.unavailable :

        theme.controls.presence.offline

    border.color: theme.controls.presence.border
    border.width: theme.controls.presence.borderWidth

    Behavior on color   { HColorAnimation {} }
    Behavior on opacity { HNumberAnimation {} }

    HoverHandler { id: presenceHover }

    HToolTip {
        visible: presenceHover.hovered
        text:
            presence.includes("online") ? qsTr("Online") :
            presence.includes("unavailable") ? qsTr("Unavailable") :
            presence.includes("invisible") ? qsTr("Invisible") :
            qsTr("Offline")
    }
}
