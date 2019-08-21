import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    HListView {
        id: memberList

        model: HListModel {
            keyField: "user_id"
            source: Utils.filterModelSource(
                modelSources[["Member", chatPage.roomId]] || [],
                filterField.text
            )
        }

        delegate: MemberDelegate {
            width: memberList.width
        }

        Layout.fillWidth: true
        Layout.fillHeight: true

    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter members")
        backgroundColor: theme.sidePane.filterRooms.background
        bordered: false

        Layout.fillWidth: true
        Layout.preferredHeight: theme.baseElementsHeight
    }
}
