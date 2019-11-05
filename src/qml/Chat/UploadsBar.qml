import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

Rectangle {
    id: uploadsBar
    implicitWidth: 800
    implicitHeight: firstDelegate ? firstDelegate.height : 0
    color: theme.chat.typingMembers.background
    opacity: implicitHeight ? 1 : 0


    property int delegateHeight: 0
    property int maxShownDelegates: 1

    readonly property var firstDelegate:
        uploadsList.contentItem.visibleChildren[0]


    Behavior on implicitHeight { HNumberAnimation {} }

    HListView {
        id: uploadsList
        enableFlicking: false
        width: parent.width

        model: HListModel {
            keyField: "uuid"
            source: modelSources[["Upload", chatPage.roomId]] || []
        }

        delegate: HColumnLayout {
            id: delegate
            width: uploadsList.width
            Component.onCompleted: Utils.debug(delegate)

            HRowLayout {
                HLabel {
                    id: filenameLabel
                    elide: Text.ElideRight
                    text:
                        model.status === "Starting" ?
                        qsTr("Preparing %1...").arg(fileName) :

                        model.status === "Encrypting" ?
                        qsTr("Encrypting %1...").arg(fileName) :

                        model.status === "Uploading" ?
                        qsTr("Uploading %1...").arg(fileName) :

                        model.status === "CreatingThumbnail" ?
                        qsTr("Generating thumbnail for %1...").arg(fileName) :

                        model.status === "EncryptingThumbnail" ?
                        qsTr("Encrypting thumbnail for %1...").arg(fileName) :

                        model.status === "UploadingThumbnail" ?
                        qsTr("Uploading thumbnail for %1...").arg(fileName) :

                        model.status === "Failure" ?
                        qsTr("Failed uploading %1.").arg(fileName) :

                        qsTr("Invalid status for %1: %2")
                        .arg(fileName, model.status)

                    topPadding: theme.spacing / 2
                    bottomPadding: topPadding
                    leftPadding: theme.spacing / 1.5
                    rightPadding: leftPadding

                    Layout.fillWidth: true

                    readonly property string fileName:
                        model.filepath.split("/").slice(-1)[0]
                }

                HSpacer {}

                HLabel {
                    id: uploadCountLabel
                    visible: Layout.preferredWidth > 0
                    text: qsTr("%1/%2")
                          .arg(model.index + 1).arg(uploadsList.model.count)

                    topPadding: theme.spacing / 2
                    bottomPadding: topPadding
                    leftPadding: theme.spacing / 1.5
                    rightPadding: leftPadding

                    Layout.preferredWidth:
                        uploadsList.model.count < 2 ? 0 : implicitWidth

                    Behavior on Layout.preferredWidth { HNumberAnimation {} }
                }
            }

            HProgressBar {
                id: progressBar

                Layout.fillWidth: true
            }
        }
    }
}
