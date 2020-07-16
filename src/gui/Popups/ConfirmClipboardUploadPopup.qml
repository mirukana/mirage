// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../Base"
import "../Base/Buttons"

HColumnPopup {
    id: popup

    property string userId
    property string roomId
    property string roomName


    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: uploadButton
            text: qsTr("Send")
            icon.name: "confirm-uploading-file"
            onClicked: {
                py.callClientCoro(
                    popup.userId,
                    "send_clipboard_image",
                    [popup.roomId, Clipboard.image],
                )
                popup.close()
            }
        }

        CancelButton {
            id: cancelButton
            onClicked: popup.close()
        }
    }

    onOpened: uploadButton.forceActiveFocus()

    SummaryLabel {
        text:
            qsTr("Send copied image to %1?")
            .arg(utils.htmlColorize(roomName, theme.colors.accentText))

        textFormat: Text.StyledText
    }

    HImage {
        id: image

        property int updateCounter: 0

        source: "image://clipboard/" + updateCounter
        fillMode: Image.PreserveAspectFit

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight:
            status === Image.Ready ?
            width / (implicitWidth / implicitHeight) :
            96 * theme.uiScale  // for spinner

        Behavior on Layout.preferredHeight { HNumberAnimation {} }

        Connections {
            target: Clipboard

            function onContentChanged() {
                Clipboard.hasImage ? image.updateCounter += 1 : popup.close()
            }
        }
    }
}
