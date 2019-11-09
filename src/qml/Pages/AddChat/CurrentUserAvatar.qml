import QtQuick 2.12
import "../../Base"

HUserAvatar {
    clientUserId: addChatPage.userId
    userId: clientUserId
    displayName: addChatPage.account ? addChatPage.account.display_name : ""
    mxc: addChatPage.account ? addChatPage.account.avatar_url : ""
}
