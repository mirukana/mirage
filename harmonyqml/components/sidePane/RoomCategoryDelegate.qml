import QtQuick 2.7
import "../base" as Base

Base.HLabel {
    width: roomList.width
    height: text.height

    // topPadding is provided by the roomList spacing
    bottomPadding: roomList.spacing

    text: section
    elide: Text.ElideRight
    maximumLineCount: 1

    font.bold: true
}
