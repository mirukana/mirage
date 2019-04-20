import QtQuick 2.7
import "../base" as Base

Base.HLabel {
    text: date_time.toLocaleDateString()
    width: messageDelegate.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: messageDelegate.isFirstMessage ?
                0 : messageDelegate.standardSpacing
    bottomPadding: messageDelegate.standardSpacing
    font.pixelSize: normalSize * 1.1
    color: "darkolivegreen"
}
