// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

HAvatar {
    property string userId: ""
    readonly property var userInfo: userId ? users.find(userId) : ({})

    readonly property var defaultImageUrl:
        userInfo.avatarUrl ? ("image://python/" + userInfo.avatarUrl) : null

    readonly property var defaultToolTipImageUrl:
        userInfo.avatarUrl ? ("image://python/" + userInfo.avatarUrl) : null

    name: userInfo.displayName || userId.substring(1)  // no leading @
    imageUrl: defaultImageUrl
    toolTipImageUrl:defaultToolTipImageUrl

    //HImage {
        //id: status
        //anchors.right: parent.right
        //anchors.bottom: parent.bottom
        //source: "../../icons/status.svg"
        //sourceSize.width: 12
    //}
}
