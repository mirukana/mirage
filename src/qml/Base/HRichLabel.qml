import QtQuick 2.7

HLabel {
    id: label
    textFormat: Text.RichText

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true

        onPositionChanged: function (event) {
            cursorShape = label.linkAt(event.x, event.y) ?
                          Qt.PointingHandCursor : Qt.ArrowCursor
        }

        onClicked: function(event) {
            var link = label.linkAt(event.x, event.y)
            event.accepted = Boolean(link)
            if (link) { Qt.openUrlExternally(link) }
        }
    }
}
