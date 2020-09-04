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

    signal aboutToRecycle()
    signal recycled()
    signal previousShown(string componentUrl, var properties)

    function show(componentUrl, properties={}) {
        history.unshift([componentUrl, properties])
        if (history.length > historyLength) history.pop()

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
        window.uiStateChanged()
    }

    function showRoom(userId, roomId) {
        show("Pages/Chat/Chat.qml", {userId, roomId})
    }

    function showPrevious(timesBack=1) {
        timesBack = Math.min(timesBack, history.length - 1)
        if (timesBack < 1) return false

        const [componentUrl, properties] = history[timesBack]
        show(componentUrl, properties)
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
        sequences: window.settings.keys.goToLastPage
        onActivated: showPrevious()
    }
}
