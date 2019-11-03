import QtQuick 2.12

HAvatar {
    name: displayName || userId.substring(1)  // no leading @


    property string userId
    property string displayName
}
