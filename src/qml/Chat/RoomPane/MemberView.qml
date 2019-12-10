import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    HListView {
        id: memberList
        clip: true

        Layout.fillWidth: true
        Layout.fillHeight: true


        readonly property var originSource:
                modelSources[["Member", chat.roomId]] || []


        onOriginSourceChanged: filterLimiter.restart()


        function filterSource() {
            model.source =
                Utils.filterModelSource(originSource, filterField.text)
        }


        model: HListModel {
            keyField: "user_id"
            source: memberList.originSource
        }

        delegate: MemberDelegate {
            width: memberList.width
        }

        Timer {
            id: filterLimiter
            interval: 16
            onTriggered: memberList.filterSource()
        }
    }

    HRowLayout {
        Layout.minimumHeight: theme.baseElementsHeight
        Layout.maximumHeight: Layout.minimumHeight

        HTextField {
            id: filterField
            placeholderText: qsTr("Filter members")
            backgroundColor: theme.chat.roomPane.filterMembers.background
            bordered: false
            opacity: width >= 16 ? 1 : 0

            onTextChanged: filterLimiter.restart()

            Layout.fillWidth: true
            Layout.fillHeight: true

            Behavior on opacity { HOpacityAnimator {} }
        }

        HButton {
            enabled: false  // TODO
            icon.name: "room-send-invite"
            topPadding: 0
            bottomPadding: 0
            toolTip.text: qsTr("Invite to this room")
            backgroundColor: theme.chat.roomPane.inviteButton.background

            Layout.fillHeight: true
        }
    }
}
