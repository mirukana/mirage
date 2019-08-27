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

        HNumberAnimation {
            id: blink
            target: icon
            property: "opacity"
            from: 1
            to: 0.3
            factor: 2
            running: button.loading || false
            onStopped: { [from, to] = [to, from]; start() }
        }

        HNumberAnimation {
            target: icon
            property: "scale"
            from: 1
            to: 0.92
            factor: blink.factor
            running: blink.running
            onStopped: { [from, to] = [to, from]; start() }
        }


        SequentialAnimation {
            running: blink.running
            loops: Animation.Infinite

            HPauseAnimation { factor: blink.factor * 8 }

            HNumberAnimation {
                id: rotation1
                target: icon
                property: "rotation"
                from: 0
                to: 180
                factor: blink.factor
            }

            HPauseAnimation { factor: blink.factor * 8 }

            HNumberAnimation {
                target: rotation1.target
                property: rotation1.property
                from: rotation1.to
                to: 360
                factor: rotation1.factor
            }
        }
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
