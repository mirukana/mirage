import QtQuick.Layouts 1.3
import "../Base"

HRowLayout {
    id: toolBar

    Layout.fillWidth: true
    Layout.preferredHeight: 32

    HButton {
        iconName: "settings"
        backgroundColor: HStyle.sidePane.settingsButton.background
    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter rooms")
        backgroundColor: HStyle.sidePane.filterRooms.background

        onTextChanged: Backend.setRoomFilter(text)

        Layout.fillWidth: true
        Layout.preferredHeight: 32
    }
}
