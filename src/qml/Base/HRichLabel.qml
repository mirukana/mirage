import QtQuick 2.12

HLabel {
    // https://blog.shantanu.io/2015/02/15/creating-working-hyperlinks-in-qtquick-text/
    id: label
    textFormat: Text.RichText
    onLinkActivated: Qt.openUrlExternally(link)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
