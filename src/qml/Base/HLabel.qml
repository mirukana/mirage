// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick.Controls 2.12
import QtQuick 2.12

Label {
    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    textFormat: Label.PlainText

    color: theme.colors.text
    linkColor: theme.colors.link

    maximumLineCount: elide == Label.ElideNone ? Number.MAX_VALUE : 1
}
