import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HListView {
    id: accountList
    clip: true

    model: HListModel {
        keyField: "user_id"
        source: modelSources["Account"] || []
    }

    delegate: AccountDelegate {}
}
