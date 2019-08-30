import QtQuick 2.12

Item {
    id: shortcutHandler

    Keys.onPressed: {
        let shortcut = match(event)
        if (! shortcut) return
        event.isAutoRepeat ? shortcut.held(event) : shortcut.pressed(event)
    }
    Keys.onReleased: {
        let shortcut = match(event)
        if (shortcut && ! event.isAutoRepeat) shortcut.released(event)
    }


    readonly property var modifierDict: ({
        Ctrl:  Qt.ControlModifier,
        Shift: Qt.ShiftModifier,
        Alt:   Qt.AltModifier,
        Meta:  Qt.MetaModifier,
    })


    function sequenceMatches(event, sequence) {
        let [key, ...mods] = sequence.split("+").reverse()

        key = key.charAt(0).toUpperCase() + key.slice(1)

        if (event.key !== Qt["Key_" + key]) return false

        for (let [name, code] of Object.entries(modifierDict)) {
            if (mods.includes(name) && ! (event.modifiers & code)) return false
            if (! mods.includes(name) && event.modifiers & code) return false
        }

        return true
    }

    function match(event) {
        for (let i = 0;  i < shortcutHandler.resources.length; i++) {
            let shortcut = shortcutHandler.resources[i]

            if (! shortcut.enabled) continue

            if (typeof(shortcut.sequences) == "string") {
                return sequenceMatches(event, shortcut.sequences) ?
                       shortcut : null
            }

            for (let i = 0;  i < shortcut.sequences.length; i++) {
                if (sequenceMatches(event, shortcut.sequences[i])) {
                    return shortcut
                }
            }
        }
        return null
    }
}
