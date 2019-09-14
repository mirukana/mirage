import QtQuick 2.12
import QtQuick.Layouts 1.12

HButton {
    id: tile

    default property var additionalItems: []

    readonly property alias title: title
    readonly property alias additionalInfo: additionalInfo
    readonly property alias rightInfo: rightInfo
    readonly property alias subtitle: subtitle

    property HMenu contextMenu: HMenu {}

    property Item image

    property Item details: HColumnLayout {
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

            visible: Layout.maximumHeight > 0
            Layout.maximumHeight: text ? implicitWidth : 0
            Layout.fillWidth: true

            Behavior on Layout.maximumHeight { HNumberAnimation {} }
        }
    }


    contentItem: HRowLayout {
        spacing: tile.spacing
        children: [image, details].concat(additionalItems)
    }


    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: if (contextMenu.count > 0) contextMenu.popup()
    }
}
