import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HTile {
    id: file
    width: Math.max(
        Math.min(eventContent.messageBodyWidth,
                 theme.chat.message.fileMinWidth),
        Math.min(eventContent.messageBodyWidth, implicitWidth),
    )

    title.text: loader.singleMediaInfo.media_title || qsTr("Untitled file")
    title.elide: Text.ElideMiddle
    subtitle.text: CppUtils.formattedBytes(loader.singleMediaInfo.media_size)

    image: HIcon {
        svgName: "download"
    }

    onLeftClicked: download(Qt.openUrlExternally)
    onRightClicked: eventDelegate.openContextMenu()

    onHoveredChanged: {
        if (! hovered) {
            eventDelegate.hoveredMediaTypeUrl = []
            return
        }

        eventDelegate.hoveredMediaTypeUrl = [
            EventDelegate.Media.File,
            loader.downloadedPath || loader.mediaUrl
        ]
    }


    property EventMediaLoader loader

    readonly property bool cryptDict: loader.singleMediaInfo.media_crypt_dict
    readonly property bool isEncrypted: ! Utils.isEmptyObject(cryptDict)
}
