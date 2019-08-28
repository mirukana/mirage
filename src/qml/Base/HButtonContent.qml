import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HRowLayout {
    id: buttonContent
    spacing: button.spacing
    opacity: loading ? theme.loadingElementsOpacity :
             enabled ? 1 : theme.disabledElementsOpacity


    property AbstractButton button
    property QtObject buttonTheme

    readonly property alias icon: icon
    readonly property alias label: label


    Behavior on opacity { HNumberAnimation {} }


    HIcon {
        property bool loading: button.loading || false

        id: icon
        svgName: button.icon.name
        colorize: enabled ? button.icon.color: theme.icons.disabledColorize
        cache: button.icon.cache

        onLoadingChanged: if (! loading) resetAnimations.start()

        Layout.fillHeight: true
        Layout.alignment: Qt.AlignCenter


        ParallelAnimation {
            id: resetAnimations
            HNumberAnimation { target: icon; property: "opacity"; to: 1 }
            HNumberAnimation { target: icon; property: "rotation"; to: 0 }
        }


        HNumberAnimation on opacity {
            id: blink
            from: 1
            to: 0.5
            factor: 2
            running: button.loading || false
            onFinished: { [from, to] = [to, from]; start() }
        }

        SequentialAnimation {
            running: button.loading || false
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
