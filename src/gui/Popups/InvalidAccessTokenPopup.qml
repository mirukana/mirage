// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup

    property string userId

    function addAccount() {
        window.mainUI.pageLoader.show("Pages/AddAccount/AddAccount.qml")
    }


    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: signBackButton
            text: qsTr("Sign back in")
            icon.name: "sign-back-in"
            onClicked: {
                addAccount()
                popup.close()
            }
        }

        CancelButton {
            text: qsTr("Close")
            onClicked: popup.close()
        }
    }

    onClosed: if (window.uiState.pageProperties.userId === userId) addAccount()

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
