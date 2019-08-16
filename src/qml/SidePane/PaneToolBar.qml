import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRowLayout {
    id: toolBar

    property alias roomFilter: filterField.text

    Layout.fillWidth: true
    Layout.preferredHeight: theme.baseElementsHeight

    HUIButton {
        iconName: "add-account"
        backgroundColor: theme.sidePane.settingsButton.background
        Layout.preferredHeight: parent.height

        onClicked: pageStack.showPage("SignIn")
    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter rooms")
        backgroundColor: theme.sidePane.filterRooms.background
        bordered: false

        Layout.fillWidth: true
        Layout.preferredHeight: parent.height

        onTextChanged: {
            if (window.uiState.sidePaneFilter == text) return
            window.uiState.sidePaneFilter = text
            window.uiStateChanged()
        }

        Connections {
            target: window
            // Keep multiple instances of PaneToolBar in sync.
            // This also sets the text on startup.
            onUiStateChanged: filterField.text = uiState.sidePaneFilter
        }

    }
}
