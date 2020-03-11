// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HFlickableColumnPage {
    HTabContainer {
        tabModel: [
            qsTr("Sign in"), qsTr("Register"), qsTr("Reset"),
        ]

        SignIn { Component.onCompleted: forceActiveFocus() }
        Register {}
        Reset {}
    }
}
