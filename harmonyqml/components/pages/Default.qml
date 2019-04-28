import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Base.HRowLayout {
    Base.HLabel {
        text: "Select or add a room to start."
        wrapMode: Text.Wrap
        padding: 3
        leftPadding: 10
        rightPadding: 10

        Layout.margins: 10
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: parent.width - Layout.margins * 2

        background: Rectangle {
            color: Qt.hsla(1, 1, 1, 0.3)
        }
    }
}
