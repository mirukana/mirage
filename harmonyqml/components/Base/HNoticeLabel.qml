import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../Base" as Base

Base.HRowLayout {
    property alias text: noticeLabel.text
    property alias color: noticeLabel.color
    property alias font: noticeLabel.font
    property alias backgroundColor: noticeLabelBackground.color
    property alias radius: noticeLabelBackground.radius

    Base.HLabel {
        id: noticeLabel
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        padding: 3
        leftPadding: 10
        rightPadding: 10

        Layout.margins: 10
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: parent.width - Layout.margins * 2

        background: Rectangle {
            id: noticeLabelBackground
            color: Base.HStyle.box.background
            radius: Base.HStyle.box.radius
        }
    }
}
