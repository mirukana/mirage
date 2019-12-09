import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRowLayout {
    id: toolBar

    property SidePaneList sidePaneList
    readonly property alias addAccountButton: addAccountButton
    readonly property alias filterField: filterField
    property alias roomFilter: filterField.text

    HButton {
        id: addAccountButton
        icon.name: "add-account"
        toolTip.text: qsTr("Add another account")
        backgroundColor: theme.sidePane.settingsButton.background
        onClicked: pageLoader.showPage("AddAccount/AddAccount")

        Layout.fillHeight: true
    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter rooms")
        backgroundColor: theme.sidePane.filterRooms.background
        bordered: false

        Component.onCompleted: filterField.text = uiState.sidePaneFilter

        onTextChanged: {
            if (window.uiState.sidePaneFilter == text) return
            window.uiState.sidePaneFilter = text
            window.uiStateChanged()
        }

        Layout.fillWidth: true
        Layout.fillHeight: true

        Keys.onUpPressed: sidePaneList.previous(false)  // do not activate
        Keys.onDownPressed: sidePaneList.next(false)

        Keys.onEnterPressed: Keys.onReturnPressed(event)
        Keys.onReturnPressed: {
            if (event.modifiers & Qt.ShiftModifier) {
                sidePaneList.toggleCollapseAccount()
                return
            }

            if (window.settings.clearRoomFilterOnEnter) text = ""
            sidePaneList.activate()
        }

        Keys.onEscapePressed: {
            if (window.settings.clearRoomFilterOnEscape) text = ""
            mainUI.pageLoader.forceActiveFocus()
        }
    }
}
