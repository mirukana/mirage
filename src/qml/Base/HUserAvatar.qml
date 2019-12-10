import QtQuick 2.12

HAvatar {
    name: displayName || userId.substring(1)  // no leading @


    property string userId
    property string displayName
    property int powerLevel: 0
    property bool shiftPowerIconPosition: true

    readonly property bool admin: powerLevel >= 100
    readonly property bool moderator: powerLevel >= 50 && ! admin


    HLoader {
        active: admin || moderator
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: shiftPowerIconPosition ? -16 / 2 : 0
        anchors.leftMargin: anchors.topMargin
        z: 100

        Behavior on anchors.topMargin { HNumberAnimation {} }

        sourceComponent: HIcon {
            small: true
            svgName: "user-power-" + (admin ? "100" : "50")
            colorize: admin ?
                      theme.chat.roomPane.member.adminIcon :
                      theme.chat.roomPane.member.moderatorIcon

            HoverHandler { id: powerIconHover }

            HToolTip {
                visible: powerIconHover.hovered
                text: admin ?
                      qsTr("Admin (%1 power)").arg(powerLevel) :
                      qsTr("Moderator (%1 power)").arg(powerLevel)
            }
        }
    }

}
