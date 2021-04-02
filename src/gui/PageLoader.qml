// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import QtGraphicalEffects 1.12
import "Base"
import "MainPane"

HLoader {
    id: pageLoader

    // List of previously loaded [componentUrl, {properties}]
    property var history: []
    property int historyLength: 20
    property int historyPosition: 0

    readonly property alias appearAnimation: appearAnimation

    signal aboutToRecycle()
    signal recycled()
    signal previousShown(string componentUrl, var properties)

    function show(componentUrl, properties={}, alterHistory=true) {
        if (alterHistory) {
            // A new branch of history will be added.
            // The new branch replaces everything after the current point.
            while (historyPosition > 0) {
                history.shift()
                historyPosition--
            }
            // Add entry to history
            history.unshift([componentUrl, properties])
            if (history.length > historyLength) history.pop()
        }

        const recycle =
            window.uiState.page === componentUrl &&
            componentUrl === "Pages/Chat/Chat.qml" &&
            item

        if (recycle) {
            aboutToRecycle()

            for (const [prop, value] of Object.entries(properties))
                item[prop] = value

            recycled()
        } else {
            pageLoader.setSource(componentUrl, properties)
            window.uiState.page = componentUrl
        }

        window.uiState.pageProperties = properties
        window.saveUIState()
    }

    function showRoom(userId, roomId) {
        show("Pages/Chat/Chat.qml", {userRoomId: [userId, roomId]})
    }

    function showPrevious(timesBack=1) {
        timesBack = Math.min(timesBack, history.length - 1)
        if (timesBack < 1) return false

        const [componentUrl, properties] = history[timesBack]
        show(componentUrl, properties)
        previousShown(componentUrl, properties)
        return true
    }

    function moveThroughHistory(relativeMovement=1) {

        if (history.length === 0) return false

        // going beyond oldest entry in history
        if (historyPosition + relativeMovement >= history.length) {
            if (!window.settings.Keys.wrap_history) return false
            relativeMovement -= history.length
        }

        // going beyond newest entry in history
        else if (historyPosition + relativeMovement < 0){
            if (!window.settings.Keys.wrap_history) return false
            relativeMovement += history.length
        }

        historyPosition += relativeMovement

        const [componentUrl, properties] = history[historyPosition]
        show(componentUrl, properties, false)
        previousShown(componentUrl, properties)
        return true
    }

    function takeFocus() {
        pageLoader.item.forceActiveFocus()
        if (mainPane.collapse) mainPane.close()
    }

    clip: appearAnimation.running

    onLoaded: { takeFocus(); appearAnimation.restart() }
    onRecycled: { takeFocus(); appearAnimation.restart() }

    Component.onCompleted: {
        if (! py.startupAnyAccountsSaved) {
            pageLoader.show("Pages/AddAccount/AddAccount.qml")
            return
        }

        pageLoader.show(window.uiState.page, window.uiState.pageProperties)
    }

    HNumberAnimation {
        id: appearAnimation
        target: pageLoader.item
        property: "x"
        from: -pageLoader.width
        to: 0
        easing.type: Easing.OutCirc
        factor: 2
    }

    HShortcut {
        sequences: window.settings.Keys.last_page
        onActivated: showPrevious()
    }

    HShortcut {
        sequences: window.settings.Keys.earlier_page
        onActivated: moveThroughHistory(1)
    }

    HShortcut {
        sequences: window.settings.Keys.later_page
        onActivated: moveThroughHistory(-1)
    }
}
