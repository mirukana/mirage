// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup

    property string userId

    signal signBackInRequest()

    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: signBackButton
            text: qsTr("Sign back in")
            icon.name: "sign-back-in"
            onClicked: {
                const page = "Pages/AddAccount/AddAccount.qml"
                window.mainUI.pageLoader.show(page)
                popup.close()
            }
        }

        CancelButton {
            text: qsTr("Close")
            onClicked: popup.close()
        }
    }

    SummaryLabel {
        text: qsTr("Signed out from %1").arg(coloredNameHtml("", userId))
        textFormat: SummaryLabel.StyledText
    }

    DetailsLabel {
        text: qsTr(
            "You have been disconnected from another session, " +
            "by the server for security reasons, or the access token in " +
            "your configuration file is invalid."
        )
    }

    onOpened: signBackButton.forceActiveFocus()
}
