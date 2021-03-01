// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: root

    property string path

    readonly property string docs:
        "https://github.com/mirukana/mirage/tree/master/docs"

    page.footer: AutoDirectionLayout {
        CancelButton {
            id: cancelButton
            text: qsTr("Close")
            onClicked: root.close()
        }
    }

    onOpened: cancelButton.forceActiveFocus()

    SummaryLabel {
        leftPadding: theme.spacing / 2
        rightPadding: leftPadding
        textFormat: SummaryLabel.StyledText
        text: qsTr("Old configuration file %1 detected").arg(
            utils.htmlColorize("settings.json", theme.colors.accentText),
        )
    }

    DetailsLabel {
        leftPadding: theme.spacing / 2
        rightPadding: leftPadding
        textFormat: DetailsLabel.StyledText
        text: qsTr(
            "The configuration format has changed and settings.json " +
            "is no longer supported. " +
            `Visit the <a href='${docs}'>new config documentation</a> for ` +
            "more info.<br><br>" +
            "This warning will stop appearing if the file " +
            `<a href='${path}'>${path.replace(/^file:\/\//, "")}</a> is ` +
            "renamed, deleted or moved away."
        )

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape:
                parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }
}
