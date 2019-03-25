import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

RowLayout {
    id: "toolBar"
    Layout.fillWidth: true
    Layout.maximumHeight: 32
    spacing: 0

    ActionButton {
        visible: ! toolBarIsBig()
        iconName: "reduced_menu"
        tooltip: "Menu"
    }

    ActionButton {
        iconName: "settings"
        tooltip: "Settings"
        targetPage: "SettingsPage"
    }

    ActionButton {
        iconName: "add_account"
        tooltip: "Add new account"
        targetPage: "AddAccountPage"
    }

    ActionButton {
        iconName: "set_status"
        tooltip: "Set status for all accounts"
    }

    ActionButton {
        iconName: "search"
        tooltip: "Filter rooms and people"
    }


    TextField {
        id: filterField
        visible: false
        placeholderText: qsTr("Filter rooms")
        selectByMouse: true
        font.family: "Roboto"
        Layout.fillWidth: true
        Layout.fillHeight: true
        background: Rectangle { color: "lightgray" }
    }
}
