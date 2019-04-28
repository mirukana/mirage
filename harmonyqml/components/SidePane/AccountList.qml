import QtQuick 2.7
import QtQuick.Layouts 1.3

ListView {
    id: accountList
    clip: true

    spacing: 8
    topMargin: spacing
    bottomMargin: topMargin
    Layout.leftMargin:
        sidePane.width <= (sidePane.Layout.minimumWidth + spacing) ?
        0 : spacing

    model: Backend.models.accounts
    delegate: AccountDelegate {}
}
