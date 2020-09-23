// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/Buttons"
import "../PythonBridge"

PasswordPopup {
    id: popup

    property string userId
    property var deviceIds  // array
    property var deletedCallback: null

    property Future deleteFuture: null

    function verifyPassword(pass, callback) {
        deleteFuture = py.callClientCoro(
            userId,
            "delete_devices_with_password",
            [deviceIds, pass],
            () => {
                deleteFuture = null
                callback(true)
            },
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


    validateButton.text:
        deviceIds.length > 1 ?
        qsTr("Sign out %1 devices").arg(deviceIds.length) :
        qsTr("Sign out %1 device").arg(deviceIds.length)

    validateButton.icon.name: "sign-out"

    onClosed: {
        if (deleteFuture) deleteFuture.cancel()

        if (deleteFuture || acceptedPassword && deletedCallback)
            deletedCallback()
    }
}
