// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRectangle {
    id: sidePane
    clip: true  // Avoid artifacts when collapsed
    // opacity: mainUI.accountsPresent && ! reduce ? 1 : 0
    // visible: opacity > 0


    property bool canAutoSize: true
    property int parentWidth: parent.width
    property real autoWidthRatio: theme.sidePane.autoWidthRatio

    // Needed for SplitView because it breaks the binding on collapse
    onParentWidthChanged: if (canAutoSize) {
        width = Qt.binding(() => implicitWidth)
    }


    property int autoWidth:
        Math.min(parentWidth * autoWidthRatio, theme.sidePane.maximumAutoWidth)

    property bool collapse:
        canAutoSize ?
        autoWidth < theme.sidePane.autoCollapseBelowWidth :
        width <= theme.sidePane.collapsedWidth

    property bool reduce:
        window.width < theme.sidePane.autoReduceBelowWindowWidth

    property int implicitWidth:
        reduce   ? 0 :
        collapse ? theme.sidePane.collapsedWidth :
        autoWidth

    property int currentSpacing:
        collapse || reduce ? 0 : theme.spacing

    Behavior on currentSpacing { HNumberAnimation {} }
    Behavior on implicitWidth  { HNumberAnimation {} }


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
