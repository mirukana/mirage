// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

HAvatar {
    property string userId: ""
    property string roomId: ""

    readonly property var roomInfo: rooms.getWhere({userId, roomId}, 1)[0]

    // roomInfo ? → Avoid error messages when a room is forgotten
    readonly property var dname: roomInfo ? roomInfo.displayName : ""

    name:
        dname[0] == "#" && dname.length > 1 ? dname.substring(1) : dname

    imageUrl:
        roomInfo.avatarUrl ?  ("image://python/" + roomInfo.avatarUrl) : null

    toolTipImageUrl:
        roomInfo.avatarUrl ?  ("image://python/" + roomInfo.avatarUrl) : null
}
