// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import CppUtils 0.1
import "../../.."
import "../../../Base"
import "../../../Base/HTile"

HTile {
    id: file

    property EventMediaLoader loader


    width: Math.min(
        eventDelegate.width,
        eventContent.maxMessageWidth,
        Math.max(theme.chat.message.fileMinWidth, implicitWidth),
    )
    height: Math.max(theme.chat.message.avatarSize, implicitHeight)

    contentItem: ContentRow {
        tile: file

        HIcon {
            svgName: "download"
        }

        HColumnLayout {
            TitleLabel {
                elide: Text.ElideMiddle
                text: loader.singleMediaInfo.media_title ||
                      qsTr("Untitled file")
            }

            SubtitleLabel {
                tile: file
                text: CppUtils.formattedBytes(
                    loader.singleMediaInfo.media_size,
                )
            }
        }
    }

    onMiddleClicked: leftClicked()
    onRightClicked: eventDelegate.openContextMenu()
    onLeftClicked:
        eventList.selectedCount ?
        eventDelegate.toggleChecked() :

        loader.isMedia ?
        eventList.openMediaExternally(singleMediaInfo) :

        Qt.openUrlExternally(loader.mediaUrl)

    onHoveredChanged: {
        if (! hovered) {
            eventDelegate.hoveredMediaTypeUrl = []
            return
        }

        eventDelegate.hoveredMediaTypeUrl =
            [Utils.Media.File, loader.mediaUrl, loader.title]
    }

    Binding on backgroundColor {
        value: theme.chat.message.checkedBackground
        when: eventDelegate.checked
    }

    Behavior on backgroundColor { HColorAnimation {} }
}
