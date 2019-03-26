import QtQuick 2.7
import "../base" as Base

Base.HLabel {
    text: date_time.toLocaleDateString()
    width: rootCol.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: rootCol.isFirstMessage ? 0 : rootCol.verticalPadding * 4
    bottomPadding: rootCol.verticalPadding * 2
    font.pixelSize: normalSize * 1.1
    color: "darkolivegreen"
}
