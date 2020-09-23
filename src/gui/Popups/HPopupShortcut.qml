// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import "../Base"

HShortcut {
    enabled: active

    onSequencesChanged: check()
    onSequenceChanged: check()

    function check() {
        if (sequences.includes("Escape") || sequence === "Escape")
            console.warn(
                qsTr("%1: assigning Escape to a popup action causes conflicts")
                    .arg(sequence || JSON.stringify(sequences))
            )
    }
}
