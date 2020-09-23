// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import CppUtils 0.1
import "."

Timer {
    readonly property ListModel accounts: ModelStore.get("accounts")
    readonly property var accountsSet: new Set()

    function setPresence(userId, presence) {
        py.callClientCoro(userId, "set_presence", [presence, undefined, false])
    }


    interval: 1000
    repeat: true
    running:
        window.settings.beUnavailableAfterSecondsIdle > 0 &&
        CppUtils.idleMilliseconds() !== -1

    onTriggered: {
        let changes = false

        const beUnavailable =
            CppUtils.idleMilliseconds() / 1000 >=
            window.settings.beUnavailableAfterSecondsIdle

        for (let i = 0; i < accounts.count; i++) {
            const account = accounts.get(i)

            if (! account.presence_support) continue

            if (beUnavailable && account.presence === "online") {
                setPresence(account.id, "unavailable")
                accountsSet.add(account.id)
                changes = true

            } else if (! beUnavailable && accountsSet.has(account.id)) {
                setPresence(account.id, "online")
                accountsSet.delete(account.id)
                changes = true
            }
        }

        if (changes) accountsSetChanged()
    }
}
