import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRowLayout {
    id: toolBar

    readonly property alias addAccountButton: addAccountButton
    readonly property alias filterField: filterField
    property alias roomFilter: filterField.text

    Layout.fillWidth: true
    Layout.minimumHeight: theme.baseElementsHeight
    Layout.maximumHeight: Layout.minimumHeight

    HButton {
        id: addAccountButton
        icon.name: "add-account"
        toolTip.text: qsTr("Add another account")
        backgroundColor: theme.sidePane.settingsButton.background
        onClicked: pageLoader.showPage("SignIn")

        Layout.fillHeight: true
    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter rooms")
        backgroundColor: theme.sidePane.filterRooms.background
        bordered: false

        Layout.fillWidth: true
        Layout.fillHeight: true

        onTextChanged: {
            if (window.uiState.sidePaneFilter == text) return
            window.uiState.sidePaneFilter = text
            window.uiStateChanged()
        }

        Connections {
            target: window
            // Keep multiple instances of SidePaneToolBar in sync.
            // This also sets the text on startup.
            onUiStateChanged: filterField.text = uiState.sidePaneFilter
        }

    }
}
