import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HRowLayout {
    property alias label: noticeLabel
    property alias text: noticeLabel.text
    property alias color: noticeLabel.color
    property alias font: noticeLabel.font
    property alias backgroundColor: noticeLabelBackground.color
    property alias radius: noticeLabelBackground.radius

    HLabel {
        id: noticeLabel
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        padding: 3
        leftPadding: 10
        rightPadding: 10

        Layout.margins: 10
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth:
            parent.width - Layout.leftMargin - Layout.rightMargin

        opacity: width > Layout.leftMargin + Layout.rightMargin ? 1 : 0

        background: Rectangle {
            id: noticeLabelBackground
            color: HStyle.box.background
            radius: HStyle.box.radius
        }
    }
}
