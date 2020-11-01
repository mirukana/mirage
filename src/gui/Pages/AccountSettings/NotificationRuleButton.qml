// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../Base"

HButton {
    property string toggles: ""

    readonly property string key: JSON.stringify([model.kind, model.id])

    readonly property bool on:
        toggles && page.pendingEdits[key] && toggles in page.pendingEdits[key]?
        page.pendingEdits[key][toggles] :

        toggles ?
        model[toggles] :

        true


    opacity: on ? 1 : theme.disabledElementsOpacity
    hoverEnabled: true
    backgroundColor: "transparent"

    onClicked: {
        if (! toggles) return

        if (! (key in page.pendingEdits)) page.pendingEdits[key] = {}

        if ((! on) === model[toggles])
            delete page.pendingEdits[key][toggles]
        else
            page.pendingEdits[key][toggles] = ! on

        if (! Object.keys(page.pendingEdits[key]).length)
            delete page.pendingEdits[key]

        page.pendingEditsChanged()
    }

    Behavior on opacity { HNumberAnimation {} }
}
