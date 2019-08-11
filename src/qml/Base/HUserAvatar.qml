// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

HAvatar {
    property string userId: ""
    property string displayName: ""
    property string avatarUrl: ""

    readonly property var defaultImageUrl:
        avatarUrl ? ("image://python/" + avatarUrl) : null

    readonly property var defaultToolTipImageUrl:
        avatarUrl ? ("image://python/" + avatarUrl) : null

    name: displayName || userId.substring(1)  // no leading @
    imageUrl: defaultImageUrl
    toolTipImageUrl:defaultToolTipImageUrl
}
