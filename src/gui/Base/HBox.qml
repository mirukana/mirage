// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: box
    color: theme.controls.box.background
    radius: theme.radius
    implicitWidth: theme.controls.box.defaultWidth
    implicitHeight: childrenRect.height

    Keys.onReturnPressed: if (clickButtonOnEnter) enterClickButton()
    Keys.onEnterPressed: Keys.onReturnPressed(event)


    property alias buttonModel: buttonRepeater.model
    property var buttonCallbacks: []
    property string focusButton: ""
    property string clickButtonOnEnter: ""

    property bool fillAvailableHeight: false

    property HButton firstButton: null

    default property alias body: interfaceBody.data


    function enterClickButton() {
        for (let i = 0; i < buttonModel.length; i++) {
            const btn = buttonRepeater.itemAt(i)
            if (btn.enabled && btn.name === clickButtonOnEnter) btn.clicked()
        }
    }


    HNumberAnimation on scale {
        running: true
        from: 0
        to: 1
        overshoot: 3
    }

    HColumnLayout {
        id: mainColumn
        width: parent.width

        Binding on height {
            value: box.height
            when: box.fillAvailableHeight
        }

        HColumnLayout {
            id: interfaceBody
            spacing: theme.spacing * 1.5

            Layout.margins: spacing
        }

        HGridLayout {
            id: buttonGrid
            visible: buttonModel.length > 0
            flow: width >= buttonRepeater.summedImplicitWidth ?
                  GridLayout.LeftToRight : GridLayout.TopToBottom

            HRepeater {
                id: buttonRepeater
                model: []

                onItemAdded:
                    if (index === 0) firstButton = buttonRepeater.itemAt(0)

                onItemRemoved:
                    if (index === 0) firstButton = null

                HButton {
                    id: button
                    text: modelData.text
                    icon.name: modelData.iconName || ""
                    icon.color: modelData.iconColor || (
                        name === "ok" || name === "apply" || name === "retry" ?
                        theme.colors.positiveBackground :

                        name === "cancel" ?
                        theme.colors.negativeBackground :

                        theme.icons.colorize
                    )

                    enabled:
                        modelData.enabled === undefined ?
                        true : modelData.enabled

                    loading: modelData.loading || false

                    disableWhileLoading:
                        modelData.disableWhileLoading === undefined ?
                        true : modelData.disableWhileLoading

                    onClicked: buttonCallbacks[name](button)

                    Keys.onLeftPressed: previous.forceActiveFocus()
                    Keys.onUpPressed: previous.forceActiveFocus()
                    Keys.onRightPressed: next.forceActiveFocus()
                    Keys.onDownPressed: next.forceActiveFocus()
                    Keys.onReturnPressed: if (button.enabled) button.clicked()
                    Keys.onEnterPressed: Keys.onReturnPressed(event)

                    Component.onCompleted:
                        if (name === focusButton) forceActiveFocus()

                    Layout.fillWidth: true
                    Layout.preferredHeight: theme.baseElementsHeight


                    property string name: modelData.name

                    property Item next: buttonRepeater.itemAt(
                        utils.numberWrapAt(index + 1, buttonRepeater.count),
                    )
                    property Item previous: buttonRepeater.itemAt(
                        utils.numberWrapAt(index - 1, buttonRepeater.count),
                    )
                }
            }
        }
    }
}
