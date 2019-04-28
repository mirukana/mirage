import QtQuick 2.7
import "../Base"

HLabel {
    width: roomList.width

    // topPadding is provided by the roomList spacing
    bottomPadding: roomList.spacing

    text: section
    elide: Text.ElideRight
    maximumLineCount: 1

    font.weight: Font.DemiBold
}
