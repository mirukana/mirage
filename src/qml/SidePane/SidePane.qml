import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRectangle {
    id: sidePane
    clip: true  // Avoid artifacts when collapsed
    opacity: mainUI.accountsPresent && ! reduce ? 1 : 0
    visible: opacity > 0

    color: theme.sidePane.background

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


    HColumnLayout {
        anchors.fill: parent

        AccountList {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: currentSpacing
            bottomMargin: currentSpacing
        }

        PaneToolBar {
            id: paneToolBar
        }
    }
}
