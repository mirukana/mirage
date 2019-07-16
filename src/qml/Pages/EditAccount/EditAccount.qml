// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HPage {
    id: editAccount

    property int avatarPreferredSize: theme.minimumSupportedWidth

    property string userId: ""
    readonly property var userInfo: users.find(userId)

    page.header: HRectangle {
        width: parent.width
        color: theme.pageHeadersBackground

        height: window.height <
                avatarPreferredSize +
                theme.baseElementsHeight +
                currentSpacing * 2 ?
                0 : theme.baseElementsHeight

        Behavior on height { HNumberAnimation {} }
        visible: height > 0

        HRowLayout {
            width: parent.width

            HLabel {
                text: qsTr("Account settings for %1").arg(
                    Utils.coloredNameHtml(userInfo.displayName, userId)
                )
                textFormat: Text.StyledText
                font.pixelSize: theme.fontSize.big
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter

                Layout.leftMargin: currentSpacing
                Layout.rightMargin: Layout.leftMargin
                Layout.fillWidth: true
            }
        }
    }

    HRectangle {
        color: theme.box.background

        Layout.alignment: Qt.AlignCenter

        Layout.maximumWidth: Math.min(parent.width, 640)
        Layout.preferredWidth:
            wide ? parent.width : avatarPreferredSize

        Layout.preferredHeight: childrenRect.height

        Profile { width: parent.width }
    }

    // HRectangle {
        // color: theme.box.background
        // radius: theme.box.radius
        // ClientSettings { width: parent.width }
    // }

    // HRectangle {
        // color: theme.box.background
        // radius: theme.box.radius
        // Devices { width: parent.width }
    // }
}
