import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

Rectangle {
    id: uploadsBar
    implicitWidth: 800
    implicitHeight: firstDelegate ? firstDelegate.height : 0
    color: theme.chat.uploadsBar.background
    opacity: implicitHeight ? 1 : 0
    clip: true


    property int delegateHeight: 0

    readonly property var firstDelegate:
        uploadsList.contentItem.visibleChildren[0]

    readonly property alias uploadsCount: uploadsList.count


    Behavior on implicitHeight { HNumberAnimation {} }

    HListView {
        id: uploadsList
        anchors.fill: parent

        model: HListModel {
            keyField: "uuid"
            source: modelSources[["Upload", chatPage.roomId]] || []
        }

        delegate: HColumnLayout {
            id: delegate
            width: uploadsList.width

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
                        .arg(fileName).arg(model.status)

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
                    text: qsTr("%1")
                          .arg(CppUtils.formattedBytes(model.total_size))

                    topPadding: theme.spacing / 2
                    bottomPadding: topPadding
                    leftPadding: theme.spacing / 1.5
                    rightPadding: leftPadding

                    Layout.preferredWidth:
                        model.status === "Uploading" ? implicitWidth : 0

                    Behavior on Layout.preferredWidth { HNumberAnimation {} }
                }
            }

            HProgressBar {
                id: progressBar
                indeterminate: true
                Layout.fillWidth: true
            }
        }
    }
}
