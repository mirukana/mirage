import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HRectangle {
    id: sidePane
    clip: true
    opacity: mainUI.accountsPresent && ! reduce ? 1 : 0
    visible: opacity > 0

    color: theme.sidePane.background

    property bool hasFocus: paneToolBar.filterField.activeFocus
    property alias accountRoomList: accountRoomList
    property alias paneToolBar: paneToolBar

    property real autoWidthRatio: theme.sidePane.autoWidthRatio
    property bool manuallyResizing: false
    property bool manuallyResized: false
    property int manualWidth: 0
    property bool animateWidth: true

    Component.onCompleted: {
        if (window.uiState.sidePaneManualWidth) {
            manualWidth     = window.uiState.sidePaneManualWidth
            manuallyResized = true
        }
    }

    onFocusChanged: if (focus) paneToolBar.filterField.forceActiveFocus()

    onManualWidthChanged: {
        window.uiState.sidePaneManualWidth = manualWidth
        window.uiStateChanged()
    }

    property int maximumCalculatedWidth: Math.min(
        manuallyResized ? manualWidth : theme.sidePane.maximumAutoWidth,
        window.width - theme.minimumSupportedWidthPlusSpacing
    )

    property int parentWidth: parent.width
    // Needed for SplitView since it breaks the binding when user manual sizes
    onParentWidthChanged: width = Qt.binding(() => implicitWidth)


    property int calculatedWidth: Math.min(
        manuallyResized ? manualWidth : parentWidth * autoWidthRatio,
        maximumCalculatedWidth
    )

    property bool collapse:
        (manuallyResizing ? width : calculatedWidth) <
        (manuallyResized ?
         (theme.sidePane.collapsedWidth + theme.spacing * 2) :
         theme.sidePane.autoCollapseBelowWidth)

    property bool reduce:
        window.width < theme.sidePane.autoReduceBelowWindowWidth

    property int implicitWidth:
        reduce   ? 0 :
        collapse ? theme.sidePane.collapsedWidth :
        calculatedWidth

    property int currentSpacing:
        width <= theme.sidePane.collapsedWidth + theme.spacing * 2 ?
        0 : theme.spacing

    Behavior on currentSpacing { HNumberAnimation {} }
    Behavior on implicitWidth  {
        HNumberAnimation { factor: animateWidth ? 1 : 0 }
    }


    function setFocus() {
        forceActiveFocus()
        if (reduce) {
            pageLoader.item.currentIndex = 0
        }
    }


    HColumnLayout {
        anchors.fill: parent

        AccountRoomList {
            id: accountRoomList
            clip: true

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        PaneToolBar {
            id: paneToolBar
        }
    }
}
