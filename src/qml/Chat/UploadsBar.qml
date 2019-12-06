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

            property bool guiPaused: false

            readonly property bool paused:
                model.status === "Paused" || guiPaused

            Behavior on height { HNumberAnimation {} }

            Binding {
                id: hideBind
                target: delegate
                property: "height"
                value: 0
                when: false
            }

            HRowLayout {
                HButton {
                    icon.name: "upload-cancel"
                    icon.color: theme.colors.negativeBackground
                    padded: false

                    onClicked: {
                        // Python might take a sec to cancel, but we want
                        // immediate visual feedback
                        hideBind.when = true
                        // Python will delete this model item on cancel
                        py.call(py.getattr(model.task, "cancel"))
                    }

                    Layout.preferredWidth: theme.baseElementsHeight
                    Layout.fillHeight: true
                }

                HLabel {
                    id: statusLabel
                    elide: expand ? Text.ElideNone : Text.ElideRight
                    wrapMode: expand ? Text.Wrap : Text.NoWrap

                    color: model.status === "Error" ?
                           theme.colors.errorText : theme.colors.text

                    text:
                        model.status === "Uploading" ?
                        qsTr("Uploading %1...").arg(fileName) :

                        model.status === "Caching" ?
                        qsTr("Caching %1...").arg(fileName) :

                        model.status === "UploadingThumbnail" ?
                        qsTr("Uploading thumbnail for %1...").arg(fileName) :

                        model.status === "CachingThumbnail" ?
                        qsTr("Caching thumbnail for %1...").arg(fileName) :

                        model.status === "Error" ? (
                            model.error === "MatrixForbidden" ?
                            qsTr("Forbidden file type or quota exceeded: %1")
                            .arg(fileName) :

                            model.error === "MatrixTooLarge" ?
                            qsTr("Too large for this server: %1")
                            .arg(fileName) :

                            model.error === "IsADirectoryError" ?
                            qsTr("Can't upload folders, need a file: %1")
                            .arg(filePath) :

                            model.error === "FileNotFoundError" ?
                            qsTr("Non-existant file: %1")
                            .arg(filePath) :

                            model.error === "PermissionError" ?
                            qsTr("No permission to read this file: %1")
                            .arg(filePath) :

                            qsTr("Unknown error for %1: %2 - %3")
                            .arg(filePath)
                            .arg(model.error)
                            .arg(model.error_args)
                        ) :

                        qsTr("Invalid status for %1: %2")
                        .arg(fileName).arg(model.status)

                    topPadding: theme.spacing / 2
                    bottomPadding: topPadding
                    leftPadding: theme.spacing / 1.5
                    rightPadding: leftPadding

                    Layout.fillWidth: true

                    property bool expand: model.status === "Error"

                    readonly property string fileName:
                        model.filepath.split("/").slice(-1)[0]

                    readonly property string filePath:
                        model.filepath.replace(/^file:\/\//, "")

                    HoverHandler { id: statusLabelHover }

                    HToolTip {
                        text: parent.truncated ? parent.text : ""
                        visible: text && statusLabelHover.hovered
                    }
                }

                HSpacer {}

                HLabel {
                    id: uploadCountLabel
                    visible: Layout.preferredWidth > 0
                    text: qsTr("-%1  %2/s  %3/%4")
                          .arg(model.time_left ?
                               Utils.formatDuration(msLeft) : "∞")
                          .arg(CppUtils.formattedBytes(model.speed))
                          .arg(CppUtils.formattedBytes(uploaded))
                          .arg(CppUtils.formattedBytes(model.total_size))

                    topPadding: theme.spacing / 2
                    bottomPadding: topPadding
                    leftPadding: theme.spacing / 1.5
                    rightPadding: leftPadding

                    Layout.preferredWidth:
                        model.status === "Uploading" ? implicitWidth : 0

                    property int msLeft: model.time_left || -1
                    property int uploaded: model.uploaded

                    Behavior on msLeft { HNumberAnimation { duration: 1000 } }
                    Behavior on uploaded { HNumberAnimation { duration: 1000 }}

                    Behavior on Layout.preferredWidth { HNumberAnimation {} }
                }

                HButton {
                    visible: Layout.preferredWidth > 0
                    padded: false

                    icon.name: delegate.paused ?
                               "upload-resume" : "upload-pause"

                    icon.color: delegate.paused ?
                                theme.colors.positiveBackground :
                                theme.colors.middleBackground

                    toolTip.text: delegate.paused ?
                                  qsTr("Resume") : qsTr("Pause")

                    onClicked: {
                        delegate.guiPaused = ! delegate.guiPaused
                        py.setattr(
                            model.monitor, "pause", delegate.guiPaused,
                        )
                    }

                    Layout.preferredWidth:
                        model.status === "Uploading" ?
                        theme.baseElementsHeight : 0

                    Layout.fillHeight: true

                    Behavior on Layout.preferredWidth { HNumberAnimation {} }
                }

                TapHandler {
                    onTapped: if (model.status !== "Error")
                        statusLabel.expand = ! statusLabel.expand
                }
            }

            HProgressBar {
                id: progressBar
                visible: Layout.maximumHeight !== 0
                indeterminate: model.status !== "Uploading"
                value: model.uploaded
                to: model.total_size

                // TODO: bake this in hprogressbar
                foregroundColor:
                    model.status === "Error" ?
                    theme.controls.progressBar.errorForeground :

                    delegate.paused ?
                    theme.controls.progressBar.pausedForeground :

                    theme.controls.progressBar.foreground

                Layout.fillWidth: true
                Layout.maximumHeight:
                    model.status === "Error" && indeterminate ? 0 : -1

                Behavior on value { HNumberAnimation { duration: 1000 } }
                Behavior on Layout.maximumHeight { HNumberAnimation {} }
            }
        }
    }
}
