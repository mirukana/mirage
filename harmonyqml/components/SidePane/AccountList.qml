import QtQuick 2.7
import QtQuick.Layouts 1.0

ListView {
    id: accountList
    clip: true

    spacing: 8
    Layout.leftMargin: spacing
    topMargin: spacing
    bottomMargin: topMargin

    model: Backend.models.accounts
    delegate: AccountDelegate {}
}
