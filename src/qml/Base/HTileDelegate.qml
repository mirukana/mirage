import QtQuick 2.12
import QtQuick.Layouts 1.12

HButton {
    id: tile


    signal activated()
    signal highlightMe()


    property bool isCurrent: false

    readonly property var delegateModel: model

    default property var additionalItems: []

    readonly property alias title: title
    readonly property alias additionalInfo: additionalInfo
    readonly property alias rightInfo: rightInfo
    readonly property alias subtitle: subtitle

    property Item image

    property Item details: HColumnLayout {
        Layout.fillWidth: true

        HRowLayout {
            spacing: tile.spacing

            HLabel {
                id: title
                text: "Title"
                elide: Text.ElideRight
                verticalAlignment: Qt.AlignVCenter

                Layout.fillWidth: true
            }

            HRowLayout {
                id: additionalInfo
            }

            HLabel {
                id: rightInfo
                font.pixelSize: theme.fontSize.small

                visible: Layout.maximumWidth > 0
                Layout.maximumWidth:
                    text && tile.width >= 200 ? implicitWidth : 0

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

    onIsCurrentChanged: if (isCurrent) highlightMe()
    onHighlightMe: accountRoomList.currentIndex = model.index

    onClicked: {
        ListView.highlightRangeMode = ListView.NoHighlightRange
        ListView.highlightMoveDuration = 0
        activated()
        ListView.highlightRangeMode = ListView.ApplyRange
        ListView.highlightMoveDuration = theme.animationDuration
    }


    Timer {
        interval: 100
        repeat: true
        running: ListView.currentIndex == -1
        // Component.onCompleted won't work for this
        onTriggered: if (isCurrent) highlightMe()
    }

    // Connections {
        // target: ListView
        // onHideHoverHighlight: tile.hovered = false
    // }

}
