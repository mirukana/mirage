// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    summary.text: qsTr("Unexpected error occured: <i>%1</i>").arg(errorType)
    summary.textFormat: Text.StyledText

    okText: qsTr("Report")
    okIcon: "report-error"
    okEnabled: false  // TODO
    cancelText: qsTr("Ignore")
    box.focusButton: "cancel"


    property string errorType
    property var errorArguments: []
    property string traceback: ""


    HScrollableTextArea {
        text: traceback || qsTr("No traceback available")
        area.readOnly: true

        Layout.fillWidth: true
    }

    HCheckBox {
        text: qsTr("Hide this type of error until restart")
        onCheckedChanged:
            checked ?
            window.hideErrorTypes.add(errorType) :
            window.hideErrorTypes.delete(errorType)

        Layout.fillWidth: true
    }
}
