// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Layouts 1.3

HScalingBox {
    id: interfaceBox

    property alias title: interfaceTitle.text
    property alias buttonModel: interfaceButtonsRepeater.model
    property var buttonCallbacks: []
    property string enterButtonTarget: ""

    default property alias body: interfaceBody.children

    function clickEnterButtonTarget() {
        for (var i = 0; i < buttonModel.length; i++) {
            var btn = interfaceButtonsRepeater.itemAt(i)
            if (btn.name === enterButtonTarget) { btn.clicked() }
        }
    }

    HColumnLayout {
        anchors.fill: parent
        id: mainColumn

        HRowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: interfaceBox.margins

            HLabel {
                id: interfaceTitle
                font.pixelSize: theme.fontSize.big
            }
        }

        HSpacer {}

        HColumnLayout { id: interfaceBody }

        HSpacer {}

        HRowLayout {
            Repeater {
                id: interfaceButtonsRepeater
                model: []

                HButton {
                    property string name: modelData.name

                    id: button
                    text: modelData.text
                    iconName: modelData.iconName || ""
                    onClicked: buttonCallbacks[modelData.name](button)

                    Layout.fillWidth: true
                    Layout.preferredHeight: theme.avatar.size
                }
            }
        }
    }
}
