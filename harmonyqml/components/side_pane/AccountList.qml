import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ListView {
    id: "accountList"
    spacing: 8
    model: Backend.models.accounts
    delegate: AccountDelegate {}
    clip: true
}
