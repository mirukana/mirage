import QtQuick 2.12

QtObject {
    property int cooldown: 250
    property bool extendOnRequestWhileCooldownActive: false

    property bool firePending: false

    readonly property Timer timer: Timer {
        property bool extended: false

        interval: cooldown
        onTriggered: {
            if (firePending) {
                if (extendOnRequestWhileCooldownActive && ! extended) {
                    firePending = false
                    extended = true
                    running = true
                    return
                }

                fired()
                firePending = false
                extended = false
            } else if (extended) {
                fired()
                extended = false
            }
        }
    }


    signal requestFire()
    signal fired()

    onRequestFire: {
        if (timer.running) {
            firePending = true
            return
        }

        fired()
        firePending   = false
        timer.running = true
    }
}
