// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

SignInBase {
    id: page

    function takeFocus() { copyUrlButton.forceActiveFocus() }

    function startSignIn() {
        errorMessage.text = ""

        page.loginFutureId = py.callCoro("start_sso_auth",[serverUrl], url => {
            urlArea.text           = url
            urlArea.cursorPosition = 0

            Qt.openUrlExternally(url)

            page.loginFutureId = py.callCoro("continue_sso_auth",[],userId => {
                page.loginFutureId = ""
                page.finishSignIn(userId)
            })
        })
    }

    function cancel() {
        if (loginFutureId) {
            py.cancelCoro(page.loginFutureId)
            page.loginFutureId = ""
        }

        page.exitRequested()
    }


    implicitWidth: theme.controls.box.defaultWidth * 1.25
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

    HRowLayout {
        HTextArea {
            id: urlArea
            width: parent.width
            readOnly: true
            radius: 0
            wrapMode: HTextArea.WrapAnywhere

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        FieldCopyButton {
            id: copyUrlButton
            textControl: urlArea
        }
    }
}
