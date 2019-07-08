// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Controls 2.2

ScrollView {
    property alias backgroundColor: textAreaBackground.color
    property alias placeholderText: textArea.placeholderText
    property alias text: textArea.text
    property alias area: textArea

    default property alias textAreaData: textArea.data

    id: scrollView
    clip: true

    TextArea {
        id: textArea
        readOnly: ! visible
        selectByMouse: true

        wrapMode: TextEdit.Wrap
        font.family: theme.fontFamily.sans
        font.pixelSize: theme.fontSize.normal

        color: theme.colors.foreground
        background: Rectangle {
            id: textAreaBackground
            color: theme.controls.textArea.background
        }
    }
}
