import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HTile {
    onLeftClicked: Qt.openUrlExternally(loader.mediaUrl)
    onRightClicked: eventDelegate.openContextMenu()

    // TODO: have the right URL, not mxc
    onHoveredChanged:
        eventDelegate.hoveredMediaTypeUrl =
            hovered ? [EventDelegate.Media.File, loader.mediaUrl] : []


    property EventMediaLoader loader


    title.text: loader.singleMediaInfo.media_title || qsTr("Untitled file")
    title.elide: Text.ElideMiddle

    subtitle.text: CppUtils.formattedBytes(loader.singleMediaInfo.media_size)

    image: HIcon {
        svgName: "download"
    }
}
