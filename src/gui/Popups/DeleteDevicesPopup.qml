// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/ButtonLayout"

PasswordPopup {
    id: popup


    property string userId
    property var deviceIds  // array
    property var deletedCallback: null


    function verifyPassword(pass, callback) {
        py.callClientCoro(
            userId,
            "delete_devices_with_password",
            [deviceIds, pass],
            () => callback(true),
            (type, args) => {
                callback(
                    type === "MatrixUnauthorized" ?
                    false :
                    qsTr("Unknown error: %1 - %2").arg(type).arg(args)
                )
            },
        )
    }

    summary.text:
        qsTr("Enter your account's password to continue:")


    validateButton.text: qsTr("Sign out")
    validateButton.icon.name: "sign-out"

    onClosed: if (acceptedPassword && deletedCallback) deletedCallback()
}
