// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/ButtonLayout"

HFlickableColumnPopup {
    id: popup


    property string userId
    property string deviceIds


    page.footer: ButtonLayout {
        CancelButton {
            id: cancelButton
            onClicked: popup.close()
        }
    }

    onOpened: cancelButton.forceActiveFocus()

    SummaryLabel { text: qsTr("Not implemented yet") }
}
