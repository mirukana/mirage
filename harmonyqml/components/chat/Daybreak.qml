import QtQuick 2.7
import "../base" as Base

Base.HLabel {
    property bool isToday: {
      const today = new Date()
      return dateTime.getDate() == today.getDate() &&
             dateTime.getMonth() == today.getMonth() &&
             dateTime.getFullYear() == today.getFullYear()
    }

    width: messageDelegate.width
    topPadding: messageDelegate.isFirstMessage ?
                0 : messageDelegate.standardSpacing
    bottomPadding: messageDelegate.standardSpacing

    text: dateTime.toLocaleDateString() + (isToday ? qsTr(" (Today)") : "")
    horizontalAlignment: Text.AlignHCenter
    font.pixelSize: normalSize * 1.1
    color: "darkolivegreen"
}
