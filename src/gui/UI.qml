// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.7
import QtGraphicalEffects 1.12
import "Base"
import "MainPane"

Item {
    id: mainUI
    focus: true

    Component.onCompleted: window.mainUI = mainUI


    property bool accountsPresent:
        (modelSources["Account"] || []).length > 0 ||
        py.startupAnyAccountsSaved

    readonly property alias shortcuts: shortcuts
    readonly property alias mainPane: mainPane
    readonly property alias pageLoader: pageLoader
    readonly property alias pressAnimation: pressAnimation


    SequentialAnimation {
        id: pressAnimation
        HNumberAnimation {
            target: mainUI; property: "scale";  from: 1.0; to: 0.9
        }
        HNumberAnimation {
            target: mainUI; property: "scale";  from: 0.9; to: 1.0
        }
    }

    GlobalShortcuts {
        id: shortcuts
        defaultDebugConsoleLoader: debugConsoleLoader
    }

    DebugConsoleLoader {
        id: debugConsoleLoader
        active: false
    }

    HImage {
        id: mainUIBackground
        visible: Boolean(Qt.resolvedUrl(source))
        fillMode: Image.PreserveAspectCrop
        source: theme.ui.image
        sourceSize.width: Screen.width
        sourceSize.height: Screen.height
        anchors.fill: parent
        asynchronous: false
    }

    LinearGradient {
        id: mainUIGradient
        anchors.fill: parent
        start: theme.ui.gradientStart
        end: theme.ui.gradientEnd

        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.ui.gradientStartColor }
            GradientStop { position: 1.0; color: theme.ui.gradientEndColor }
        }
    }

    MainPane {
        id: mainPane
    }

    PageLoader {
        id: pageLoader
        anchors.fill: parent
        anchors.leftMargin: mainPane.visibleSize
        visible: ! mainPane.hidden || anchors.leftMargin < width
    }
}
