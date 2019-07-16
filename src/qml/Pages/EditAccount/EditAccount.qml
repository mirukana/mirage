// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Page {
    id: editAccount

    property bool wide: width > 414 + padding * 2
    property int avatarPreferredSize: theme.minimumSupportedWidth
    property int normalSpacing: 8
    property int currentSpacing:
        Math.min(normalSpacing * width / 400, normalSpacing * 2)

    property string userId: ""
    readonly property var userInfo: users.find(userId)

    header: HRectangle {
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

    background: null

    leftPadding: currentSpacing < 8 ? 0 : currentSpacing
    rightPadding: leftPadding
    Behavior on leftPadding { HNumberAnimation {} }

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: boxColumn.childrenRect.height
        interactive: contentWidth > width || contentHeight > height

        HColumnLayout {
            id: boxColumn
            spacing: 16
            width: flickable.width
            height: flickable.height

            HRectangle {
                color: theme.box.background
                // radius: theme.box.radius

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
    }
}
