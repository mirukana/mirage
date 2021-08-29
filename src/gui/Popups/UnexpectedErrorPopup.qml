// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"
import "../PythonBridge" as PythonBridge

HColumnPopup {
    id: root

    property var errors: []  // [{type, message, traceback}]

    background: Rectangle {
        color: theme.controls.popup.opaqueBackground
            ? theme.controls.popup.opaqueBackground
            : theme.controls.popup.background // fallback
    }

    contentWidthLimit: Math.min(window.width / 1.5, 864 * theme.uiScale)

    page.footer: AutoDirectionLayout {
        PositiveButton {
            id: reportButton
            text: qsTr("Report")
            icon.name: "report-error"
            onClicked: Qt.openUrlExternally(
                "https://github.com/mirukana/mirage/blob/master/docs/" +
                "CONTRIBUTING.md#issues"
            )
        }

        CancelButton {
            text: qsTr("Ignore")
            onClicked: root.close()
        }
    }

    onErrorsChanged: if (errors.length) open()
    onOpened: reportButton.forceActiveFocus()
    onClosed: {
        errors = []
        errorsChanged()
    }

    Behavior on implicitHeight { HNumberAnimation {} }

    SummaryLabel {
        readonly property string types: {
            const colored = []
            const color   = theme.colors.accentText

            for (const error of root.errors) {
                const coloredType = utils.htmlColorize(error.type, color)
                if (! colored.includes(coloredType)) colored.push(coloredType)
            }

            return colored.join(", ")
        }

        textFormat: Text.StyledText
        text:
            root.errors.length > 1 ?
            qsTr("Unexpected errors occured: %1").arg(types) :
            qsTr("Unexpected error occured: %1").arg(types)
    }

    HScrollView {
        clip: true

        Layout.fillWidth: true
        Layout.fillHeight: true

        HTextArea {
            id: detailsArea
            readOnly: true
            font.family: theme.fontFamily.mono
            focusItemOnTab: hideCheckBox
            text: {
                const parts = []

                for (const error of root.errors) {
                    parts.push(error.type + ": " + (error.message || "..."))
                    parts.push(error.traceback || qsTr("Traceback missing"))
                    parts.push("─".repeat(30))
                }

                return parts.slice(0, -1).join("\n\n")  // Leave out last ────
            }
        }
    }

    HCheckBox {
        id: hideCheckBox
        text:
            root.errors.length > 1 ?
            qsTr("Hide these types of error until restart") :
            qsTr("Hide this type of error until restart")

        onCheckedChanged: {
            for (const error of errors)
                checked ?
                PythonBridge.Globals.hideErrorTypes.add(error.type) :
                PythonBridge.Globals.hideErrorTypes.delete(error.type)
        }

        Layout.fillWidth: true
    }
}
