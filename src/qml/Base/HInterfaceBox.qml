import QtQuick 2.12
import QtQuick.Layouts 1.12

HRectangle {
    id: interfaceBox
    color: theme.controls.box.background
    implicitWidth: Math.min(
        parent.width, theme.minimumSupportedWidthPlusSpacing * multiplyWidth
    )
    implicitHeight: childrenRect.height

    property real multiplyWidth: 1.0
    property real multiplyHorizontalSpacing: 1.5
    property real multiplyVerticalSpacing: 1.5

    property int horizontalSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing) *
        multiplyHorizontalSpacing

    property int verticalSpacing: theme.spacing * multiplyVerticalSpacing

    property alias title: interfaceTitle.text
    property alias buttonModel: interfaceButtonsRepeater.model
    property var buttonCallbacks: []
    property string enterButtonTarget: ""

    default property alias body: interfaceBody.children

    function clickEnterButtonTarget() {
        for (let i = 0; i < buttonModel.length; i++) {
            let btn = interfaceButtonsRepeater.itemAt(i)
            if (btn.enabled && btn.name === enterButtonTarget) btn.clicked()
        }
    }

    Keys.onReturnPressed: clickEnterButtonTarget()
    Keys.onEnterPressed: clickEnterButtonTarget()

    HColumnLayout {
        id: mainColumn
        width: parent.width
        spacing: interfaceBox.verticalSpacing

        HLabel {
            id: interfaceTitle
            visible: Boolean(text)
            font.pixelSize: theme.fontSize.bigger
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap

            Layout.fillWidth: true
            Layout.topMargin: interfaceBox.verticalSpacing
            Layout.leftMargin: interfaceBox.horizontalSpacing
            Layout.rightMargin: interfaceBox.horizontalSpacing
        }

        HColumnLayout {
            id: interfaceBody
            spacing: interfaceBox.verticalSpacing

            Layout.fillWidth: true
            Layout.leftMargin: interfaceBox.horizontalSpacing
            Layout.rightMargin: interfaceBox.horizontalSpacing
        }

        HRowLayout {
            Repeater {
                id: interfaceButtonsRepeater
                model: []

                HButton {
                    property string name: modelData.name

                    id: button
                    text: modelData.text
                    icon.name: modelData.iconName || ""
                    enabled: modelData.enabled && ! button.loading
                    onClicked: buttonCallbacks[modelData.name](button)

                    Layout.fillWidth: true
                    Layout.preferredHeight: theme.baseElementsHeight
                }
            }
        }
    }
}
