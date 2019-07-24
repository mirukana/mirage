// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

Item {
    property Item flickTarget: Item {}

    function smartVerticalFlick(baseVelocity, fastMultiply=3) {
        if (! flickTarget.interactive) { return }

        baseVelocity = -baseVelocity
        let vel      = -flickTarget.verticalVelocity
        let fast     = (baseVelocity < 0 && vel < baseVelocity / 2) ||
                       (baseVelocity > 0 && vel > baseVelocity / 2)

        flickTarget.flick(0, baseVelocity * (fast ? fastMultiply : 1))
    }

    Shortcut {
        sequences: ["Alt+Up", "Alt+K"]
        onActivated: smartVerticalFlick(-335)
    }

    Shortcut {
        sequences: ["Alt+Down", "Alt+J"]
        onActivated: smartVerticalFlick(335)
    }

    Shortcut {
        sequence: "Alt+Shift+D"
        onActivated: if (window.debug) { py.call("APP.pdb") }
    }

    /*
    Shortcut {
        sequence: "Ctrl+-"
        onActivated: theme.fontScale = Math.max(0.1, theme.fontScale - 0.1)
    }

    Shortcut {
        sequence: "Ctrl++"
        onActivated: theme.fontScale = Math.min(10, theme.fontScale + 0.1)
    }

    Shortcut {
        sequence: "Ctrl+="
        onActivated: theme.fontScale = 1.0
    }
    */
}
