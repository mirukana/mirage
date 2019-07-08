// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Controls 2.2

TextField {
    property alias backgroundColor: textFieldBackground.color

    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal

    color: theme.colors.foreground
    background: Rectangle {
        id: textFieldBackground
        color: theme.controls.textField.background
    }

    selectByMouse: true
}
