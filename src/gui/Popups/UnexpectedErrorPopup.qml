// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"
import "../PythonBridge" as PythonBridge

HColumnPopup {
    id: popup

    property string errorType
    property string message: ""
    property string traceback: ""

    page.footer: AutoDirectionLayout {
        PositiveButton {
            text: qsTr("Report")
            icon.name: "report-error"
            enabled: false  // TODO
        }

        CancelButton {
            id: cancelButton
            text: qsTr("Ignore")
            onClicked: popup.close()
        }
    }

    onOpened: cancelButton.forceActiveFocus()

    SummaryLabel {
        text: qsTr("Unexpected error occured: %1").arg(
            utils.htmlColorize(errorType, theme.colors.accentText),
        )
        textFormat: Text.StyledText
    }

    HScrollView {
        clip: true

        Layout.fillWidth: true
        Layout.fillHeight: true

        HTextArea {
            text: [message, traceback].join("\n\n") || qsTr("No info available")
            readOnly: true
            font.family: theme.fontFamily.mono
            focusItemOnTab: hideCheckBox
        }
    }

    HCheckBox {
        id: hideCheckBox
        text: qsTr("Hide this type of error until restart")
        onCheckedChanged:
            checked ?
            PythonBridge.Globals.hideErrorTypes.add(errorType) :
            PythonBridge.Globals.hideErrorTypes.delete(errorType)

        Layout.fillWidth: true
    }
}
