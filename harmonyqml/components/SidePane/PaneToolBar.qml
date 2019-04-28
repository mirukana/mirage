import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../Base" as Base

Base.HRowLayout {
    id: toolBar

    Layout.fillWidth: true
    Layout.preferredHeight: 32

    Base.HButton {
        iconName: "settings"
        backgroundColor: Base.HStyle.sidePane.settingsButton.background
    }

    Base.HTextField {
        id: filterField
        placeholderText: qsTr("Filter rooms")
        backgroundColor: Base.HStyle.sidePane.filterRooms.background

        Layout.fillWidth: true
        Layout.preferredHeight: 32
    }
}
