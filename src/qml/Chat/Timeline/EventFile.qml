import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HTile {
    width: Math.min(
        mainColumn.width - eventContent.spacing * 2,
        theme.chat.message.thumbnailWidth,
    )


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


    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: Qt.openUrlExternally(file.fileUrl)
    }

    HoverHandler {
        id: hover
        onHoveredChanged:
            eventContent.hoveredImage = hovered ? file.fileUrl : ""
    }
}
