import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../utils.js" as Utils

Rectangle {
    id: interfaceBox
    color: theme.controls.box.background
    implicitWidth: Math.min(
        parent.width, theme.minimumSupportedWidthPlusSpacing * multiplyWidth
    )
    implicitHeight: childrenRect.height

    Keys.onReturnPressed: if (clickButtonOnEnter) enterClickButton()
    Keys.onEnterPressed: Keys.onReturnPressed(event)


    property real multiplyWidth: 1.0
    property real multiplyHorizontalSpacing: 1.5
    property real multiplyVerticalSpacing: 1.5

    property int horizontalSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing) *
        multiplyHorizontalSpacing

    property int verticalSpacing: theme.spacing * multiplyVerticalSpacing

    property alias title: interfaceTitle.text
    property alias buttonModel: buttonRepeater.model
    property var buttonCallbacks: []
    property string focusButton: ""
    property string clickButtonOnEnter: ""

    default property alias body: interfaceBody.data


    function enterClickButton() {
        for (let i = 0; i < buttonModel.length; i++) {
            let btn = buttonRepeater.itemAt(i)
            if (btn.enabled && btn.name === clickButtonOnEnter) btn.clicked()
        }
    }


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
            Layout.topMargin:
                interfaceTitle.visible ? 0 : interfaceBox.verticalSpacing
            Layout.leftMargin: interfaceBox.horizontalSpacing
            Layout.rightMargin: interfaceBox.horizontalSpacing
        }

        HRowLayout {
            visible: buttonModel.length > 0

            Repeater {
                id: buttonRepeater
                model: []

                HButton {
                    id: button
                    text: modelData.text
                    icon.name: modelData.iconName || ""
                    icon.color: modelData.iconColor || (
                        name == "ok" || name == "apply" || name == "retry" ?
                        theme.colors.positiveBackground :

                        name == "cancel" ?
                        theme.colors.negativeBackground :

                        theme.icons.colorize
                    )

                    enabled: (modelData.enabled == undefined ?
                              true : modelData.enabled) &&
                             ! button.loading

                    onClicked: buttonCallbacks[name](button)

                    Keys.onLeftPressed: previous.forceActiveFocus()
                    Keys.onUpPressed: previous.forceActiveFocus()
                    Keys.onRightPressed: next.forceActiveFocus()
                    Keys.onDownPressed: next.forceActiveFocus()
                    Keys.onReturnPressed: if (button.enabled) button.clicked()
                    Keys.onEnterPressed: Keys.onReturnPressed(event)

                    Component.onCompleted:
                        if (name == focusButton) forceActiveFocus()

                    Layout.fillWidth: true
                    Layout.preferredHeight: theme.baseElementsHeight


                    property string name: modelData.name

                    property Item next: buttonRepeater.itemAt(
                        Utils.numberWrapAt(index + 1, buttonRepeater.count),
                    )
                    property Item previous: buttonRepeater.itemAt(
                        Utils.numberWrapAt(index - 1, buttonRepeater.count),
                    )
                }
            }
        }
    }
}
