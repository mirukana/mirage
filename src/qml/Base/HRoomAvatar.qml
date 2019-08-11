import QtQuick 2.12

HAvatar {
    property string displayName: ""
    property string avatarUrl: ""

    name: displayName[0] == "#" && displayName.length > 1 ?
          displayName.substring(1) :
          displayName

    imageUrl: avatarUrl ? ("image://python/" + avatarUrl) : null
    toolTipImageUrl: avatarUrl ? ("image://python/" + avatarUrl) : null
}
