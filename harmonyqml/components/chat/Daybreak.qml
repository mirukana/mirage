import QtQuick 2.7
import "../base" as Base

Base.HLabel {
    width: messageDelegate.width
    topPadding: messageDelegate.isFirstMessage ?
                0 : messageDelegate.standardSpacing
    bottomPadding: messageDelegate.standardSpacing

    text: dateTime.toLocaleDateString()
    horizontalAlignment: Text.AlignHCenter
    font.pixelSize: normalSize * 1.1
    color: "darkolivegreen"
}
