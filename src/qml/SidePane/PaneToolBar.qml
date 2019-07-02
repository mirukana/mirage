import QtQuick.Layouts 1.3
import "../Base"

HRowLayout {
    id: toolBar

    property alias roomFilter: filterField.text

    Layout.fillWidth: true
    Layout.preferredHeight: HStyle.bottomElementsHeight

    HButton {
        iconName: "settings"
        backgroundColor: HStyle.sidePane.settingsButton.background
    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter rooms")
        backgroundColor: HStyle.sidePane.filterRooms.background

        Layout.fillWidth: true
        Layout.preferredHeight: parent.height
    }
}
