import QtQuick 2.12
import "Base"

HLoader {
    id: loader

    onLoaded: {
        if (! isDefault)
            shortcuts.defaultDebugConsoleLoader.active = false

        if (shortcuts.debugConsoleLoader)
            shortcuts.debugConsoleLoader.active = false

        shortcuts.debugConsoleLoader = this
    }

    onActiveChanged: if (! active) shortcuts.debugConsoleLoader = null

    Component.onDestruction: shortcuts.debugConsoleLoader = null

    sourceComponent: DebugConsole {
        target: loader.target

        property HLoader parentLoader: loader
    }


    property QtObject target: parent

    readonly property bool isDefault:
        shortcuts.defaultDebugConsoleLoader &&
        shortcuts.defaultDebugConsoleLoader === this


    function toggle() {
        if (! loader.active) {
            loader.active = true
            return
        }

        loader.item.visible = ! loader.item.visible
    }
}
