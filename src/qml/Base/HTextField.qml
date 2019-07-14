// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12

TextField {
    property bool bordered: false
    property alias backgroundColor: textFieldBackground.color
    property alias radius: textFieldBackground.radius

    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal

    color: theme.colors.foreground
    background: Rectangle {
        id: textFieldBackground
        color: theme.controls.textField.background
        border.color: theme.controls.textField.borderColor
        border.width: bordered ? theme.controls.textField.borderWidth : 0
    }

    selectByMouse: true
}
