// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Clipboard 0.1

HMenu {
    id: menu

    property Item control: parent  // HTextField or HTextArea

    property bool enableCustomImagePaste: false
    property bool hadPersistentSelection: false  // TODO: use a Qt 5.15 Binding

    signal customImagePaste()

    function spawn(atMousePosition=true) {
        hadPersistentSelection      = control.persistentSelection
        control.persistentSelection = true

        atMousePosition ?
        popup() :
        popup(
            control.cursorRectangle.right,
            control.cursorRectangle.bottom + theme.spacing / 4,
        )
    }


    onClosed: control.persistentSelection = hadPersistentSelection
    Component.onDestruction:
        control.persistentSelection = hadPersistentSelection

    HMenuItem {
        icon.name: "undo"
        text: qsTr("Undo")
        enabled: control.canUndo
        onTriggered: control.undo()
    }

    HMenuItem {
        icon.name: "redo"
        text: qsTr("Redo")
        enabled: control.canRedo
        onTriggered: control.redo()
    }

    HMenuSeparator {}

    HMenuItem {
        icon.name: "cut-text"
        text: qsTr("Cut")
        enabled: control.selectedText
        onTriggered: control.cut()
    }

    HMenuItem {
        icon.name: "copy-text"
        text: qsTr("Copy")
        enabled: control.selectedText
        onTriggered: control.copy()
    }

    HMenuItem {
        property bool pasteImage:
            menu.enableCustomImagePaste && Clipboard.hasImage

        icon.name: "paste-text"
        text: qsTr("Paste")
        enabled: control.canPaste || pasteImage
        onTriggered: pasteImage ? menu.customImagePaste() : control.paste()
    }

    HMenuSeparator {}

    HMenuItem {
        icon.name: "select-all-text"
        text: qsTr("Select all")
        enabled: control.length > 0
        onTriggered: control.selectAll()
    }
}
