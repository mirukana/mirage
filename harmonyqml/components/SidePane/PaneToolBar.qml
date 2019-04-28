import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../Base" as Base

Base.HRowLayout {
    id: toolBar

    Layout.fillWidth: true
    Layout.preferredHeight: 32

    Base.HButton { iconName: "settings" }

    Base.HTextField {
        id: filterField
        placeholderText: qsTr("Filter rooms")

        Layout.fillWidth: true
        Layout.preferredHeight: 32
    }
}
