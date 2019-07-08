import QtQuick 2.7

HAvatar {
    property string roomId: ""

    // roomInfo ? → Avoid error messages when a room is forgotten
    readonly property var roomInfo: rooms.getWhere({"roomId": roomId}, 1)[0]
    readonly property var dname: roomInfo ? roomInfo.displayName : ""

    name: dname[0] == "#" && dname.length > 1 ? dname.substring(1) : dname
    imageUrl: roomInfo ? roomInfo.avatarUrl : null
}
