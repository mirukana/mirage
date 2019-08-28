import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HGridLayout {
    function applyChanges() {
        if (nameField.changed) {
            saveButton.nameChangeRunning = true

            py.callClientCoro(
                userId, "set_displayname", [nameField.field.text], () => {
                    saveButton.nameChangeRunning = false
                    editAccount.headerName =
                        Qt.binding(() => accountInfo.display_name)
                }
            )
        }

        if (aliasField.changed) {
            window.settings.writeAliases[userId] = aliasField.field.text
            window.settingsChanged()
        }

        if (avatar.changed) {
            saveButton.avatarChangeRunning = true
            let path = Qt.resolvedUrl(avatar.imageUrl).replace(/^file:/, "")

            py.callClientCoro(
                userId, "set_avatar_from_file", [path], response => {
                    saveButton.avatarChangeRunning = false
                    if (response != true) { print(response) }
                }
            )
        }
    }

    function cancelChanges() {
        nameField.field.text    = accountInfo.display_name
        aliasField.field.text   = aliasField.currentAlias
        fileDialog.selectedFile = ""
        fileDialog.file         = ""

        editAccount.headerName = Qt.binding(() => accountInfo.display_name)
    }

    columns: 2
    flow: pageLoader.isWide ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: currentSpacing

    Component.onCompleted: nameField.field.forceActiveFocus()

    HUserAvatar {
        property bool changed: avatar.imageUrl != avatar.defaultImageUrl

        id: avatar
        userId: editAccount.userId
        displayName: accountInfo.display_name
        avatarUrl: accountInfo.avatar_url
        imageUrl: fileDialog.selectedFile || fileDialog.file || defaultImageUrl
        toolTipImageUrl: ""

        Layout.alignment: Qt.AlignHCenter

        Layout.preferredWidth: Math.min(flickable.height, avatarPreferredSize)
        Layout.preferredHeight: Layout.preferredWidth

        Rectangle {
            z: 10
            visible: opacity > 0
            opacity: ! fileDialog.dialog.visible &&
                     (! avatar.imageUrl || avatar.hovered) ? 1 : 0

            anchors.fill: parent
            color: Utils.hsluv(0, 0, 0,
                (! avatar.imageUrl && overlayHover.hovered) ? 0.9 : 0.7
            )

            Behavior on opacity { HNumberAnimation {} }
            Behavior on color { HColorAnimation {} }

            HColumnLayout {
                anchors.centerIn: parent
                spacing: currentSpacing
                width: parent.width

                HoverHandler { id: overlayHover }

                HIcon {
                    svgName: "upload-avatar"
                    dimension: 64
                    Layout.alignment: Qt.AlignCenter
                }

                Item { Layout.preferredHeight: theme.spacing }

                HLabel {
                    text: qsTr("Upload profile picture")
                    color: (! avatar.imageUrl && overlayHover.hovered) ?
                           Qt.lighter(theme.colors.accentText, 1.2) :
                           Utils.hsluv(0, 0, 90, 1)
                    Behavior on color { HColorAnimation {} }

                    font.pixelSize: theme.fontSize.big *
                                    avatar.height / avatarPreferredSize
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Qt.AlignHCenter

                    Layout.fillWidth: true
                }
            }
        }

        HFileDialogOpener {
            id: fileDialog
            fileType: HFileDialogOpener.FileType.Images
            dialog.title: qsTr("Select profile picture for %1")
                              .arg(accountInfo.display_name)
        }
    }

    HColumnLayout {
        id: profileInfo
        spacing: theme.spacing

        HColumnLayout {
            spacing: theme.spacing
            Layout.margins: currentSpacing

            HLabel {
                text: qsTr("User ID:<br>%1")
                      .arg(Utils.coloredNameHtml(userId, userId, userId))
                textFormat: Text.StyledText
                wrapMode: Text.Wrap

                Layout.fillWidth: true
            }

            HLabeledTextField {
                property bool changed: field.text != accountInfo.display_name

                property string fText: field.text
                onFTextChanged: editAccount.headerName = field.text

                id: nameField
                label.text: qsTr("Display name:")
                field.text: accountInfo.display_name
                field.onAccepted: applyChanges()

                Layout.fillWidth: true
                Layout.maximumWidth: 480

                Keys.onEscapePressed: cancelChanges()
            }

            HLabeledTextField {
                property string currentAlias:
                    window.settings.writeAliases[userId] || ""

                property bool changed: field.text != currentAlias

                id: aliasField
                label.text: qsTr("Write alias:")
                field.text: currentAlias
                field.onAccepted: applyChanges()

                Layout.fillWidth: true
                Layout.maximumWidth: 480

                Keys.onEscapePressed: cancelChanges()
            }
        }

        HSpacer {}

        HRowLayout {
            Layout.alignment: Qt.AlignBottom

            HButton {
                property bool nameChangeRunning: false
                property bool avatarChangeRunning: false

                id: saveButton
                icon.name: "apply"
                icon.color: theme.colors.positiveBackground
                text: qsTr("Apply")
                loading: nameChangeRunning || avatarChangeRunning
                enabled:
                    nameField.changed || aliasField.changed || avatar.changed
                onClicked: applyChanges()

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
            }

            HButton {
                icon.name: "cancel"
                icon.color: theme.colors.negativeBackground
                text: qsTr("Cancel")
                enabled: saveButton.enabled && ! saveButton.loading
                onClicked: cancelChanges()

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
            }
        }
    }
}
