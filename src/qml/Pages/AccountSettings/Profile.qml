import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Dialogs"
import "../../utils.js" as Utils

HGridLayout {
    function applyChanges() {
        if (nameField.changed) {
            saveButton.nameChangeRunning = true

            py.callClientCoro(
                userId, "set_displayname", [nameField.field.text], () => {
                    saveButton.nameChangeRunning = false
                    accountSettings.headerName =
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

            let path =
                Qt.resolvedUrl(avatar.sourceOverride).replace(/^file:/, "")

            py.callClientCoro(userId, "set_avatar_from_file", [path], () => {
                saveButton.avatarChangeRunning = false
            }, (errType, [httpCode]) => {
                console.error("Avatar upload failed:", httpCode, errType)
                saveButton.avatarChangeRunning = false
            })
        }
    }

    function cancelChanges() {
        nameField.field.text    = accountInfo.display_name
        aliasField.field.text   = aliasField.currentAlias
        fileDialog.selectedFile = ""
        fileDialog.file         = ""

        accountSettings.headerName = Qt.binding(() => accountInfo.display_name)
    }

    columns: 2
    flow: pageLoader.isWide ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: currentSpacing

    Component.onCompleted: nameField.field.forceActiveFocus()

    HUserAvatar {
        property bool changed: Boolean(sourceOverride)

        id: avatar
        userId: accountSettings.userId
        displayName: nameField.field.text
        mxc: accountInfo.avatar_url
        toolTipMxc: ""
        sourceOverride: fileDialog.selectedFile || fileDialog.file

        Layout.alignment: Qt.AlignHCenter

        Layout.preferredWidth: Math.min(flickable.height, avatarPreferredSize)
        Layout.preferredHeight: Layout.preferredWidth

        Rectangle {
            z: 10
            visible: opacity > 0
            opacity: ! fileDialog.dialog.visible &&
                     ((! avatar.mxc && ! avatar.changed) || avatar.hovered) ?
                     1 : 0

            anchors.fill: parent
            color: Utils.hsluv(0, 0, 0,
                (! avatar.mxc && overlayHover.hovered) ? 0.8 : 0.7
            )

            Behavior on opacity { HNumberAnimation {} }
            Behavior on color { HColorAnimation {} }

            HoverHandler { id: overlayHover }

            HColumnLayout {
                anchors.centerIn: parent
                spacing: currentSpacing
                width: parent.width

                HIcon {
                    svgName: "upload-avatar"
                    colorize: (! avatar.mxc && overlayHover.hovered) ?
                              theme.colors.accentText : theme.icons.colorize
                    dimension: avatar.width / 3

                    Layout.alignment: Qt.AlignCenter
                }

                Item { Layout.preferredHeight: theme.spacing }

                HLabel {
                    text: avatar.mxc ?
                          qsTr("Change profile picture") :
                          qsTr("Upload profile picture")

                    color: (! avatar.mxc && overlayHover.hovered) ?
                           theme.colors.accentText : theme.colors.brightText
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
                property bool changed: field.text !== accountInfo.display_name

                readonly property string fText: field.text
                onFTextChanged: accountSettings.headerName = field.text

                id: nameField
                label.text: qsTr("Display name:")
                field.onAccepted: applyChanges()

                Component.onCompleted: field.text = accountInfo.display_name

                Keys.onEscapePressed: cancelChanges()

                Layout.fillWidth: true
                Layout.maximumWidth: 480
            }

            HLabeledTextField {
                property string currentAlias:
                    window.settings.writeAliases[userId] || ""

                property bool changed: field.text !== currentAlias

                id: aliasField
                label.text: qsTr("Write alias:")
                field.onAccepted: applyChanges()

                Component.onCompleted: field.text = currentAlias

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
                text: qsTr("Save")
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
