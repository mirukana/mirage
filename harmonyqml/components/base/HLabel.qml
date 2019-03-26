import QtQuick 2.7
import QtQuick.Controls 2.0

Label {
    property int bigSize: 24
    property int normalSize: 16
    property int smallSize: 12

    font.family: "Roboto"
    font.pixelSize: normalSize
    textFormat: Text.PlainText
}
