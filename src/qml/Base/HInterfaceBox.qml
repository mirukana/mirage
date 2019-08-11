import QtQuick 2.12
import QtQuick.Layouts 1.12

HScalingBox {
    id: interfaceBox

    property alias title: interfaceTitle.text
    property alias buttonModel: interfaceButtonsRepeater.model
    property var buttonCallbacks: []
    property string enterButtonTarget: ""

    default property alias body: interfaceBody.children

    function clickEnterButtonTarget() {
        for (let i = 0; i < buttonModel.length; i++) {
            let btn = interfaceButtonsRepeater.itemAt(i)
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
                font.pixelSize: theme.fontSize.bigger
            }
        }

        HSpacer {}

        HColumnLayout { id: interfaceBody }

        HSpacer {}

        HRowLayout {
            Repeater {
                id: interfaceButtonsRepeater
                model: []

                HUIButton {
                    property string name: modelData.name

                    id: button
                    text: modelData.text
                    iconName: modelData.iconName || ""
                    enabled: modelData.enabled === false ? false : true
                    onClicked: buttonCallbacks[modelData.name](button)

                    Layout.fillWidth: true
                    Layout.preferredHeight: theme.controls.avatar.size
                }
            }
        }
    }
}
