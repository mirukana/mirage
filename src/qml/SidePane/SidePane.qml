import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HDrawer {
    id: sidePane
    opacity: mainUI.accountsPresent ? 1 : 0
    color: theme.sidePane.background
    normalWidth: window.uiState.sidePaneManualWidth
    minNormalWidth: theme.controls.avatar.size + theme.spacing * 2

    onUserResized: {
        window.uiState.sidePaneManualWidth = newWidth
        window.uiStateChanged()
    }


    property bool hasFocus: toolBar.filterField.activeFocus
    property alias sidePaneList: sidePaneList
    property alias toolBar: toolBar


    function toggleFocus() {
        if (toolBar.filterField.activeFocus) {
            pageLoader.takeFocus()
            return
        }

        sidePane.open()
        toolBar.filterField.forceActiveFocus()
    }


    Behavior on opacity { HOpacityAnimator {} }

    HColumnLayout {
        anchors.fill: parent

        SidePaneList {
            id: sidePaneList
            clip: true

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        SidePaneToolBar {
            id: toolBar
            sidePaneList: sidePaneList

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: theme.baseElementsHeight

        }
    }
}
