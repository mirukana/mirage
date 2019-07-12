// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

HRectangle {
    id: roomSidePane

    property bool collapsed: false
    property var activeView: null

    property int normalSpacing: 8
    property int currentSpacing: collapsed ? 0 : normalSpacing

    Behavior on currentSpacing { HNumberAnimation {} }

    MembersView {
        anchors.fill: parent
    }
}
