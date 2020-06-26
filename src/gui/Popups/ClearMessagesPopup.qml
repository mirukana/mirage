// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base/ButtonLayout"

HFlickableColumnPopup {
    id: popup


    property string userId: ""
    property string roomId: ""
    property var preClearCallback: null


    page.footer: ButtonLayout {
        ApplyButton {
            id: clearButton
            text: qsTr("Clear")
            icon.name: "clear-messages"
            onClicked: {
                if (preClearCallback) preClearCallback()
                py.callClientCoro(userId, "clear_events", [roomId])
                popup.close()
            }
        }

        CancelButton {
            onClicked: popup.close()
        }
    }

    SummaryLabel {
        text: qsTr("Clear this room's messages?")
    }

    DetailsLabel {
        text: qsTr(
            "The messages will only be removed on your side. " +
            "They will be available again after you restart the application."
        )
    }

    onOpened: clearButton.forceActiveFocus()
}
