// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import "../ShortcutBundles"

HPage {
    id: page

    default property alias columnData: column.data

    property alias column: column
    property alias flickable: flickable
    property alias flickShortcuts: flickShortcuts

    property bool enableFlickShortcuts:
        SwipeView ? SwipeView.isCurrentItem : true


    implicitWidth: theme.controls.box.defaultWidth
    contentHeight:
        flickable.contentHeight + flickable.topMargin + flickable.bottomMargin

    padding: 0

    HFlickable {
        id: flickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.implicitHeight
        clip: true

        topMargin: theme.spacing
        bottomMargin: topMargin
        leftMargin: topMargin
        rightMargin: topMargin

        FlickShortcuts {
            id: flickShortcuts
            active: ! mainUI.debugConsole.visible && enableFlickShortcuts
            flickable: flickable
        }

        HColumnLayout {
            id: column
            width:
                flickable.width - flickable.leftMargin - flickable.rightMargin
            spacing: theme.spacing * 1.5
        }
    }

    HKineticScrollingDisabler {
        flickable: flickable
        width: enabled ? flickable.width : 0
        height: enabled ? flickable.height : 0
    }
}
