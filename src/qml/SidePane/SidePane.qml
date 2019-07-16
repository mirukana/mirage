// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRectangle {
    id: sidePane
    clip: true  // Avoid artifacts when collapsed
    visible: mainUI.accountsPresent


    // Properties that may be set externally

    property int parentWidth: parent.width
    onParentWidthChanged: if (canAutoSize) { width = getWidth() }

    property bool canAutoSize: true


    // Pane state properties - should not be modified

    readonly property bool reduced: width < 1
    readonly property bool collapsed:
        width < theme.sidePane.collapsedWidth + theme.spacing

    property int currentSpacing: collapsed ? 0 : theme.spacing
    Behavior on currentSpacing { HNumberAnimation {} }


    // Width functions and animations

    function getWidth() {
        var ts = theme.sidePane
        return parentWidth * ts.autoWidthRatio < ts.autoCollapseBelowWidth ?
               ts.collapsedWidth :
               Math.min(parentWidth * ts.autoWidthRatio, ts.maximumAutoWidth)
    }

    Behavior on width {
        HNumberAnimation {
            // Don't slow down the user manually resizing
            duration: (
                canAutoSize &&
                parentWidth * 0.3 < theme.sidePane.autoReduceBelowWidth * 1.2
            ) ? theme.animationDuration : 0
        }
    }


    // Pane content

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
