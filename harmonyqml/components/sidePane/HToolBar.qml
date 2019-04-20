import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

RowLayout {
    id: "toolBar"
    Layout.fillWidth: true
    Layout.maximumHeight: 32
    spacing: 0

    HToolButton {
        visible: ! toolBarIsBig()
        iconName: "reduced_menu"
        tooltip: "Menu"
    }

    HToolButton {
        iconName: "settings"
        tooltip: "Settings"
    }

    HToolButton {
        iconName: "add_account"
        tooltip: "Add new account"
    }

    HToolButton {
        iconName: "set_status"
        tooltip: "Set status for all accounts"
    }

    HToolButton {
        iconName: "search"
        tooltip: "Filter rooms"
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
