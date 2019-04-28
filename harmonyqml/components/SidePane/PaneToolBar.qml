import QtQuick.Layouts 1.0
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

        Layout.fillWidth: true
        Layout.preferredHeight: 32
    }
}
