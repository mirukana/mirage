import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HDrawer {
    id: mainPane
    saveName: "mainPane"
    color: theme.mainPane.background
    minimumSize: theme.controls.avatar.size + theme.spacing * 2


    property bool hasFocus: toolBar.filterField.activeFocus
    property alias mainPaneList: mainPaneList
    property alias toolBar: toolBar


    function toggleFocus() {
        if (toolBar.filterField.activeFocus) {
            pageLoader.takeFocus()
            return
        }

        mainPane.open()
        toolBar.filterField.forceActiveFocus()
    }


    Behavior on opacity { HOpacityAnimator {} }

    Binding on visible {
        value: false
        when: ! mainUI.accountsPresent
    }

    HColumnLayout {
        anchors.fill: parent

        AccountRoomList {
            id: mainPaneList
            clip: true

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        MainPaneToolBar {
            id: toolBar
            mainPaneList: mainPaneList

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: theme.baseElementsHeight

        }
    }
}
