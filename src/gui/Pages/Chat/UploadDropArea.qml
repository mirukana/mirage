// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "AutoCompletion"
import "Banners"
import "Composer"
import "FileTransfer"
import "Timeline"

DropArea {
    property var dragEvent: null
    property int insertedTextStart: -1
    property int insertedTextEnd: -1

    function eventFiles() {
        if (! dragEvent) return []
        return dragEvent.urls.filter(uri => uri.match(/^file:\/\//))
    }

    function reset() {
        if (popup.opened) popup.close()
        dragEvent         = null
        insertedTextStart = -1
        insertedTextEnd   = -1
    }

    onPositionChanged: drag => dragEvent = drag

    onEntered: drag => {
        print(JSON.stringify( drag, null, 4))
        dragEvent = drag
        if (eventFiles().length && ! popup.opened) popup.open()
        if (! drag.hasText || eventFiles().length) return

        insertedTextStart = composer.messageArea.cursorPosition
        composer.messageArea.insertAtCursor(drag.text.replace(/\n+$/, ""))
        insertedTextEnd = composer.messageArea.cursorPosition
    }

    onExited: {
        if (insertedTextStart !== -1 && insertedTextEnd !== -1)
            composer.messageArea.remove(insertedTextStart, insertedTextEnd)

        reset()
    }

    onDropped: drag => {
        dragEvent = drag

        for (const path of eventFiles()) {
            window.makePopup(
                "Popups/ConfirmUploadPopup.qml",
                {
                    userId: chat.userId,
                    roomId: chat.roomId,
                    roomName: chat.roomInfo.display_name,
                    filePath: path.replace(/^file:\/\//, ""),
                    replyToEventId: chat.replyToEventId,
                },
                popup => popup.replied.connect(chat.clearReplyTo),
            )
            drag.accepted = true
        }

        reset()
    }

    HPopup {
        id: popup
        background: null

        Column {
            spacing: theme.spacing

            HIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                svgName: "drop-file-upload"
                dimension: Math.min(
                    56 * theme.uiScale,
                    Math.min(window.width, window.height) / 2,
                )
            }

            HLabel {
                wrapMode: HLabel.Wrap
                width: Math.min(implicitWidth, popup.maximumPreferredWidth)
                font.pixelSize: theme.fontSize.big
                text: qsTr("Drop files to send")
            }
        }
    }
}
