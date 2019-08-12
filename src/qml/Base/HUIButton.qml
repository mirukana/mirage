import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

HBaseButton {
    property int contentWidth: 0
    property int horizontalMargin: 0
    property int verticalMargin: 0
    property int fontSize: theme.fontSize.normal

    property string iconName: ""
    property var iconDimension: null
    property var iconTransform: null

    property bool loading: false

    readonly property alias visibility: button.visible
    onVisibilityChanged: if (! visibility) { loading = false }

    id: button

    Component {
        id: buttonContent

        HRowLayout {
            id: contentLayout
            spacing: button.text && iconName ? theme.spacing : 0
            Component.onCompleted: contentWidth = implicitWidth

            HIcon {
                svgName: loading ? "hourglass" : iconName
                dimension: iconDimension || contentLayout.height
                transform: iconTransform
                opacity: button.enabled ? 1 : 0.7
                Behavior on opacity { HNumberAnimation {} }

                Layout.topMargin: verticalMargin
                Layout.bottomMargin: verticalMargin
                Layout.leftMargin: horizontalMargin
                Layout.rightMargin: horizontalMargin
            }

            HLabel {
                visible: Boolean(text)
                text: button.text
                font.pixelSize: fontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: button.enabled ?
                       theme.controls.button.text :
                       theme.controls.button.disabledText

                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: loadingOverlay
        HRowLayout {
            HIcon {
                svgName: "hourglass"
                Layout.preferredWidth: contentWidth || -1
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    contentItem: HLoader {
        sourceComponent:
            loading && ! iconName ? loadingOverlay : buttonContent
    }
}
