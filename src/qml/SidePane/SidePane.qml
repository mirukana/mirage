// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRectangle {
    id: sidePane

    // Avoid artifacts when collapsed
    clip: true

    property bool collapsed: false
    property int normalSpacing: 8
    property int currentSpacing: collapsed ? 0 : normalSpacing

    Behavior on currentSpacing { HNumberAnimation {} }

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
