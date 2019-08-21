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

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter members")
        backgroundColor: theme.sidePane.filterRooms.background
        bordered: false

        onTextChanged: filterLimiter.requestFire()

        Layout.fillWidth: true
        Layout.preferredHeight: theme.baseElementsHeight
    }
}
