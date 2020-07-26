// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

SignInBase {
    id: page

    function takeFocus() { urlField.forceActiveFocus() }

    function startSignIn() {
        errorMessage.text = ""

        page.loginFuture = py.callCoro("start_sso_auth", [serverUrl], url => {
            urlField.text           = url
            urlField.cursorPosition = 0

            Qt.openUrlExternally(url)

            page.loginFuture = py.callCoro("continue_sso_auth", [], userId => {
                page.loginFuture = null
                page.finishSignIn(userId)
            })
        })
    }


    applyButton.text: qsTr("Waiting")
    applyButton.loading: true
    Component.onCompleted: page.startSignIn()

    HLabel {
        wrapMode: HLabel.Wrap
        text: qsTr(
            "Complete the single sign-on process in your web browser to " +
            "continue.\n\n" +
            "If no page appeared, you can also manually open this address:"
        )

        Layout.fillWidth: true
    }

    HTextArea {
        id: urlField
        width: parent.width
        readOnly: true
        radius: 0
        wrapMode: HTextArea.WrapAnywhere

        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
