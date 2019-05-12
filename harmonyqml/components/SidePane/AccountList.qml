import QtQuick 2.7
import QtQuick.Layouts 1.3

ListView {
    id: accountList
    clip: true

    model: Backend.accounts
    delegate: AccountDelegate {}
}
