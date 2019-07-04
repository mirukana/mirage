import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HListView {
    id: accountList
    clip: true

    model: accounts
    delegate: AccountDelegate {}
}
