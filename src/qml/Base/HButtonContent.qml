import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HRowLayout {
    spacing: button.spacing
    opacity: enabled ? 1 : theme.disabledElementsOpacity


    property AbstractButton button
    property QtObject buttonTheme

    readonly property alias icon: icon
    readonly property alias label: label


    Behavior on opacity { HNumberAnimation {} }


    HIcon {
        id: icon
        svgName: button.icon.name
        colorize: button.icon.color
        cache: button.icon.cache

        Layout.fillHeight: true
        Layout.alignment: Qt.AlignCenter
    }

    HLabel {
        id: label
        text: button.text
        visible: Boolean(text)
        color: buttonTheme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
