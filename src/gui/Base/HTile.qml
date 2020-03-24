// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HButton {
    id: tile


    signal leftClicked()
    signal rightClicked()

    default property alias additionalData: contentItem.data

    property bool compact: window.settings.compactMode
    property real contentOpacity: 1

    readonly property alias title: title
    readonly property alias additionalInfo: additionalInfo
    readonly property alias rightInfo: rightInfo
    readonly property alias subtitle: subtitle
    readonly property Item loadedImage: imageLoader.item

    property alias contextMenu: contextMenuLoader.sourceComponent

    property Component image


    contentItem: HRowLayout {
        id: contentItem
        spacing: tile.spacing
        opacity: tile.contentOpacity

        HLoader {
            id: imageLoader
            sourceComponent: image
        }

        HColumnLayout {
            Layout.fillWidth: true

            HRowLayout {
                spacing: tile.spacing

                HLabel {
                    id: title
                    text: "Missing title"
                    elide: Text.ElideRight
                    verticalAlignment: Qt.AlignVCenter

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                HLabel {
                    id: rightInfo
                    font.pixelSize: theme.fontSize.small
                    verticalAlignment: Qt.AlignVCenter
                    color: theme.colors.halfDimText
                    visible: Layout.maximumWidth > 0

                    Layout.fillHeight: true
                    Layout.maximumWidth:
                        text && tile.width >= 200 * theme.uiScale ?
                        implicitWidth : 0

                    Behavior on Layout.maximumWidth { HNumberAnimation {} }
                }

                HRowLayout {
                    id: additionalInfo
                    visible: visibleChildren.length > 0
                }

            }

            HRichLabel {
                id: subtitle
                textFormat: Text.StyledText
                font.pixelSize: theme.fontSize.small
                verticalAlignment: Qt.AlignVCenter
                elide: Text.ElideRight
                color: theme.colors.dimText
                visible: Layout.maximumHeight > 0

                Layout.maximumHeight: ! compact && text ? implicitHeight : 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                Behavior on Layout.maximumHeight { HNumberAnimation {} }
            }
        }
    }


    Binding on topPadding {
        value: spacing / 4
        when: compact
    }

    Binding on bottomPadding {
        value: spacing / 4
        when: compact
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: leftClicked()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Pen
        onTapped: {
            rightClicked()
            if (contextMenu) contextMenuLoader.active = true
        }
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
        onLongPressed: {
            rightClicked()
            if (contextMenu) contextMenuLoader.active = true
        }
    }

    Connections {
        enabled: contextMenuLoader.status === Loader.Ready
        target: contextMenuLoader.item
        onClosed: contextMenuLoader.active = false
    }

    HLoader {
        id: contextMenuLoader
        active: false
        onLoaded: item.popup()
    }
}
