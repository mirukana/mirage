// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

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
    }
}
