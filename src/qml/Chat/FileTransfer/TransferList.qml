import QtQuick 2.12
import "../../Base"

Rectangle {
    implicitWidth: 800
    implicitHeight: firstDelegate ? firstDelegate.height : 0
    color: theme.chat.fileTransfer.background
    opacity: implicitHeight ? 1 : 0
    clip: true


    property int delegateHeight: 0

    readonly property var firstDelegate:
        transferList.contentItem.visibleChildren[0]

    readonly property alias transferCount: transferList.count


    Behavior on implicitHeight { HNumberAnimation {} }

    HListView {
        id: transferList
        anchors.fill: parent

        model: HListModel {
            keyField: "uuid"
            source: modelSources[["Upload", chatPage.roomId]] || []
        }

        delegate: Transfer { width: transferList.width }
    }
}
