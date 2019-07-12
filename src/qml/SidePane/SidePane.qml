// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HRectangle {
    id: sidePane

    // Avoid artifacts when collapsed
    clip: true

    property bool collapsed: false
    property int normalSpacing: 8
    readonly property int currentSpacing: collapsed ? 0 : normalSpacing

    HColumnLayout {
        anchors.fill: parent

        AccountList {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: currentSpacing
            bottomMargin: currentSpacing

            Behavior on spacing { HNumberAnimation {} }
        }

        PaneToolBar {
            id: paneToolBar
        }
    }
}
