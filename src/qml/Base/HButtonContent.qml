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


    Behavior on opacity { HOpacityAnimator {} }

    Item {
        id: iconWrapper

        Layout.preferredWidth: icon.width
        Layout.preferredHeight: icon.height

        ParallelAnimation {
            id: resetAnimations
            HOpacityAnimator { target: iconWrapper; to: 1 }
            HRotationAnimator { target: iconWrapper; to: 0 }
        }

        HOpacityAnimator {
            id: blink
            target: iconWrapper
            from: 1
            to: 0.5
            factor: 2
            running: button.loading || false
            onFinished: {
                if (button.loading) { [from, to] = [to, from]; start() }
            }
        }

        SequentialAnimation {
            running: button.loading || false
            loops: Animation.Infinite
            onStopped: resetAnimations.start()

            HPauseAnimation { factor: blink.factor * 8 }

            // These don't work directly on HIcon, hence why we wrap it in
            // an Item. Qt bug? (5.13.1_1)
            HRotationAnimator {
                id: rotation1
                target: iconWrapper
                from: 0
                to: 180
                factor: blink.factor
            }

            HPauseAnimation { factor: blink.factor * 8 }

            HRotationAnimator {
                target: rotation1.target
                from: rotation1.to
                to: 360
                factor: rotation1.factor
                direction: RotationAnimator.Clockwise
            }
        }

        HIcon {
            property bool loading: button.loading || false

            id: icon
            svgName: button.icon.name
            colorize: enabled ? button.icon.color: theme.icons.disabledColorize
            cache: button.icon.cache

            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
        }
    }

    HLabel {
        id: label
        text: button.text
        visible: Boolean(text)
        color: buttonTheme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
