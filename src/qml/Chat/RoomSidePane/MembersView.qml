import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    HListView {
        id: memberList

        Layout.fillWidth: true
        Layout.fillHeight: true


        readonly property var originSource:
                modelSources[["Member", chatPage.roomId]] || []


        onOriginSourceChanged: filterLimiter.requestFire()


        function filterSource() {
            model.source =
                Utils.filterModelSource(originSource, filterField.text)
        }


        model: HListModel {
            keyField: "user_id"
            source: originSource
        }

        delegate: MemberDelegate {
            width: memberList.width
        }

        HRateLimiter {
            id: filterLimiter
            cooldown: 16
            onFired: memberList.filterSource()
        }
    }

    HRowLayout {
        Layout.minimumHeight: theme.baseElementsHeight
        Layout.maximumHeight: Layout.minimumHeight

        HTextField {
            id: filterField
            placeholderText: qsTr("Filter members")
            backgroundColor: theme.chat.roomSidePane.filterMembers.background
            bordered: false

            onTextChanged: filterLimiter.requestFire()

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HButton {
            icon.name: "room-send-invite"
            iconItem.dimension: parent.height
            toolTip.text: qsTr("Invite to this room")
            backgroundColor: theme.chat.roomSidePane.inviteButton.background

            Layout.fillHeight: true
        }
    }
}
