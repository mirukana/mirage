// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

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
        wrapMode: Text.Wrap
        padding: theme.spacing / 2
        leftPadding: theme.spacing
        rightPadding: leftPadding

        Layout.margins: theme.spacing
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth:
            parent.width - Layout.leftMargin - Layout.rightMargin

        opacity: width > Layout.leftMargin + Layout.rightMargin ? 1 : 0

        background: Rectangle {
            id: noticeLabelBackground
            color: theme.controls.box.background
            radius: theme.controls.box.radius
        }
    }
}
