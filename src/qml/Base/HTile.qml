import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../utils.js" as Utils

HButton {
    id: tile

    signal leftClicked()
    signal rightClicked()

    default property alias additionalData: contentItem.data

    readonly property alias title: title
    readonly property alias additionalInfo: additionalInfo
    readonly property alias rightInfo: rightInfo
    readonly property alias subtitle: subtitle

    property HMenu contextMenu: HMenu {}

    property Component image


    contentItem: HRowLayout {
        id: contentItem
        spacing: tile.spacing

        HLoader {
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
                }

                HRowLayout {
                    id: additionalInfo
                    visible: visibleChildren.length > 0
                }

                HLabel {
                    id: rightInfo
                    font.pixelSize: theme.fontSize.small
                    color: theme.colors.halfDimText

                    visible: Layout.maximumWidth > 0
                    Layout.maximumWidth:
                        text && tile.width >= 160 ? implicitWidth : 0

                    Behavior on Layout.maximumWidth { HNumberAnimation {} }
                }
            }

            HRichLabel {
                id: subtitle
                textFormat: Text.StyledText
                font.pixelSize: theme.fontSize.small
                elide: Text.ElideRight
                color: theme.colors.dimText

                visible: Layout.maximumHeight > 0
                Layout.maximumHeight: text ? implicitWidth : 0
                Layout.fillWidth: true

                Behavior on Layout.maximumHeight { HNumberAnimation {} }
            }
        }
    }


    // Binding { target: details; property: "parent"; value: contentItem }
    // Binding { target: image; property: "parent"; value: contentItem }


    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: leftClicked()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            rightClicked()
            if (contextMenu.count > 0) contextMenu.popup()
        }
    }
}
