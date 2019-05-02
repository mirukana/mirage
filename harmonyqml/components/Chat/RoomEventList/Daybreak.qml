import QtQuick 2.7
import "../../Base"

HNoticePage {
    text: dateTime.toLocaleDateString()
    color: HStyle.chat.daybreak.foreground
    backgroundColor: HStyle.chat.daybreak.background
    radius: HStyle.chat.daybreak.radius
}
