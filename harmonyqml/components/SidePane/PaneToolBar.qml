import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
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
