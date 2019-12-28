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
    property string message: ""
    property string traceback: ""


    HScrollableTextArea {
        text: [message, traceback].join("\n\n") || qsTr("No info available")
        area.readOnly: true
        area.font.family: theme.fontFamily.mono

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
