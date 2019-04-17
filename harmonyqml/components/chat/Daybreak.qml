import QtQuick 2.7
import "../base" as Base

Base.HLabel {
    text: date_time.toLocaleDateString()
    width: rootCol.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: rootCol.isFirstMessage ? 0 : rootCol.standardSpacing
    bottomPadding: rootCol.standardSpacing
    font.pixelSize: normalSize * 1.1
    color: "darkolivegreen"
}
