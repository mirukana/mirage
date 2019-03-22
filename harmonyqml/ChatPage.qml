import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ColumnLayout {
    property var room: null

    id: chatPage
    spacing: 0
    onFocusChanged: sendBox.setFocus()

    RoomHeader {}
    MessageDisplay {}
    SendBox { id: sendBox }
}
