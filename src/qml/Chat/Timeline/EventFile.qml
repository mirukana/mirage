import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HTile {
    onLeftClicked: Qt.openUrlExternally(fileUrl)
    onRightClicked: eventDelegate.openContextMenu()

    onHoveredChanged:
        eventDelegate.hoveredMediaTypeUrl =
            hovered ? [EventDelegate.Media.File, fileUrl] : []


    property url thumbnailUrl
    property url fileUrl
    property string fileTitle: ""
    property int fileSize: 0


    title.text: fileTitle || qsTr("Untitled file")
    title.elide: Text.ElideMiddle

    subtitle.text: CppUtils.formattedBytes(fileSize)

    image: HIcon {
        svgName: "download"
    }
}
