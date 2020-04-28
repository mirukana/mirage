// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HDrawer {
    id: mainPane
    saveName: "mainPane"
    background: null
    // minimumSize: bottomBar.addAccountButton.width

    // property alias filter: bottomBar.roomFilter

    readonly property bool small:
        width < theme.controls.avatar.size + theme.spacing * 2


    Behavior on opacity { HNumberAnimation {} }

    Binding on visible {
        value: false
        when: ! mainUI.accountsPresent
    }

    HRowLayout {
        anchors.fill: parent

        AccountsBar {
            id: accountBar
            accountSwipeView: accountSwipeView

            Layout.fillWidth: false
        }

        AccountSwipeView {
            id: accountSwipeView
            currentIndex: 0

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
