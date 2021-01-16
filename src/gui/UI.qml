// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import QtGraphicalEffects 1.12
import "Base"
import "MainPane"

Item {
    id: mainUI

    property bool accountsPresent:
        ModelStore.get("accounts").count > 0 || py.startupAnyAccountsSaved

    readonly property var accountIds: {
        const ids   = []
        const model = ModelStore.get("accounts")

        for (let i = 0; i < model.count; i++)
            ids.push(model.get(i).id)

        return ids
    }

    readonly property alias debugConsole: debugConsole
    readonly property alias mainPane: mainPane
    readonly property alias pageLoader: pageLoader
    readonly property alias fontMetrics: fontMetrics
    readonly property alias idleManager: idleManager

    focus: true
    Component.onCompleted: window.mainUI = mainUI

    HShortcut {
        sequences: window.settings.Keys.python_debugger
        onActivated: py.call("BRIDGE.pdb")
    }

    HShortcut {
        sequences: window.settings.Keys.python_remote_debugger
        onActivated: py.call("BRIDGE.pdb", [[], true])
    }

    HShortcut {
        sequences: window.settings.Keys.zoom_in
        onActivated: {
            window.settings.General.zoom += 0.1
            window.saveSettings()
        }
    }

    HShortcut {
        sequences: window.settings.Keys.zoom_out
        onActivated: {
            window.settings.General.zoom =
                Math.max(0.1, window.settings.General.zoom - 0.1)

            window.saveSettings()
        }
    }

    HShortcut {
        sequences: window.settings.Keys.reset_zoom
        onActivated: {
            window.settings.General.zoom = 1
            window.saveSettings()
        }
    }

    HShortcut {
        sequences: window.settings.Keys.compact
        onActivated: {
            window.settings.General.compact = ! window.settings.General.compact
            windowsaveSettings()
        }
    }

    FontMetrics {
        id: fontMetrics
        font.family: theme.fontFamily.sans
        font.pixelSize: theme.fontSize.normal
        font.pointSize: -1
    }

    DebugConsole {
        id: debugConsole
        target: mainUI
        visible: false
    }

    IdleManager {
        id: idleManager
    }

    LinearGradient {
        id: mainUIGradient
        visible: ! image.visible
        anchors.fill: parent
        start: theme.ui.gradientStart
        end: theme.ui.gradientEnd

        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.ui.gradientStartColor }
            GradientStop { position: 1.0; color: theme.ui.gradientEndColor }
        }
    }

    HImage {
        id: image
        visible: Boolean(Qt.resolvedUrl(source))
        fillMode: Image.PreserveAspectCrop
        animatedFillMode: AnimatedImage.PreserveAspectCrop
        source: theme.ui.image
        sourceSize.width: Screen.width
        sourceSize.height: Screen.height
        anchors.fill: parent
        asynchronous: false
    }

    MainPane {
        id: mainPane
        maximumSize: parent.width - theme.minimumSupportedWidth * 1.5
    }

    PageLoader {
        id: pageLoader
        anchors.fill: parent
        anchors.leftMargin:
            mainPane.requireDefaultSize &&
            mainPane.minimumSize > mainPane.maximumSize ?
            mainPane.calculatedSizeNoRequiredMinimum :
            mainPane.visibleSize

        visible: mainPane.visibleSize < mainUI.width
    }
}
