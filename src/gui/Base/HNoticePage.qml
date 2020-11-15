// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HRowLayout {
    property alias label: noticeLabel
    property alias text: noticeLabel.text
    property alias color: noticeLabel.color
    property alias font: noticeLabel.font
    property alias backgroundColor: noticeLabelBackground.color
    property alias radius: noticeLabelBackground.radius

    HLabel {
        id: noticeLabel
        horizontalAlignment: Text.AlignHCenter
        wrapMode: HLabel.Wrap
        padding: theme.spacing / 2
        leftPadding: theme.spacing
        rightPadding: leftPadding

        opacity: width > 16 * theme.uiScale ? 1 : 0

        background: Rectangle {
            id: noticeLabelBackground
            color: theme.controls.box.background
            radius: theme.controls.box.radius
        }

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: parent.width
    }
}
