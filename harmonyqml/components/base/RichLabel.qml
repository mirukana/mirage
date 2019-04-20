import QtQuick 2.7
import QtQuick.Controls 2.0

HLabel {
    id: label
    textFormat: Text.RichText

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onPositionChanged: function (event) {
            cursorShape = label.linkAt(event.x, event.y) ?
                          Qt.PointingHandCursor : Qt.ArrowCursor
        }

        onClicked: function(event) {
            var link = label.linkAt(event.x, event.y)
            if (link) { Qt.openUrlExternally(link) }
        }
    }
}
