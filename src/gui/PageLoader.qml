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
    clip: appearAnimation.running

    onLoaded: { takeFocus(); appearAnimation.start() }

    Component.onCompleted: {
        if (! py.startupAnyAccountsSaved) {
            pageLoader.showPage(
                "AddAccount/AddAccount", {"header.show": false},
            )
            return
        }

        const page  = window.uiState.page
        const props = window.uiState.pageProperties

        if (page === "Pages/Chat/Chat.qml") {
            pageLoader.showRoom(props.userId, props.roomId)
        } else {
            pageLoader._show(page, props)
        }
    }


    property bool isWide: width > theme.contentIsWideAbove

    // List of previously loaded [componentUrl, {properties}]
    property var history: []
    property int historyLength: 20

    readonly property alias appearAnimation: appearAnimation


    function _show(componentUrl, properties={}) {
        history.unshift([componentUrl, properties])
        if (history.length > historyLength) history.pop()

        pageLoader.setSource(componentUrl, properties)
    }

    function showPage(name, properties={}) {
        const path = `Pages/${name}.qml`
        _show(path, properties)

        window.uiState.page           = path
        window.uiState.pageProperties = properties
        window.uiStateChanged()
    }

    function showRoom(userId, roomId) {
        _show("Pages/Chat/Chat.qml", {userId, roomId})

        py.callClientCoro(userId, "room_read", [roomId], () => {})

        window.uiState.page           = "Pages/Chat/Chat.qml"
        window.uiState.pageProperties = {userId, roomId}
        window.uiStateChanged()
    }

    function showPrevious(timesBack=1) {
        timesBack = Math.min(timesBack, history.length - 1)
        if (timesBack < 1) return false

        const [componentUrl, properties] = history[timesBack]

        _show(componentUrl, properties)

        window.uiState.page           = componentUrl
        window.uiState.pageProperties = properties
        window.uiStateChanged()
        return true
    }

    function takeFocus() {
        pageLoader.item.forceActiveFocus()
        if (mainPane.collapse) mainPane.close()
    }


    HNumberAnimation {
        id: appearAnimation
        target: pageLoader.item
        property: "x"
        from: -300
        to: 0
        easing.type: Easing.OutBack
        duration: theme.animationDuration * 1.5
    }

    HShortcut {
        sequences: window.settings.keys.goToLastPage
        onActivated: showPrevious()
    }
}
