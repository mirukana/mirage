// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../Base"

HButton {
    property string toggles: ""
    property var nextValue: ! on

    readonly property bool on:
        toggles && page.pendingEdits[model.id] &&
        toggles in page.pendingEdits[model.id] ?
        Boolean(page.pendingEdits[model.id][toggles]) :

        toggles ?
        Boolean(model[toggles]) :

        true


    opacity: on ? 1 : theme.disabledElementsOpacity
    hoverEnabled: true
    backgroundColor: "transparent"

    onClicked: {
        if (! toggles) return

        if (! (model.id in page.pendingEdits)) page.pendingEdits[model.id] = {}

        if ((! on) === Boolean(model[toggles]))
            delete page.pendingEdits[model.id][toggles]
        else
            page.pendingEdits[model.id][toggles] = nextValue

        if (! Object.keys(page.pendingEdits[model.id]).length)
            delete page.pendingEdits[model.id]

        page.pendingEditsChanged()
    }

    Behavior on opacity { HNumberAnimation {} }
}
