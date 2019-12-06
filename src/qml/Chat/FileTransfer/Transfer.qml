import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    id: transfer


    property bool guiPaused: false

    property int msLeft: model.time_left || 0
    property int uploaded: model.uploaded
    readonly property int speed: model.speed
    readonly property int totalSize: model.total_size
    readonly property string status: model.status
    readonly property bool paused: status === "Paused" || guiPaused


    Behavior on msLeft { HNumberAnimation { duration: 1000 } }
    Behavior on uploaded { HNumberAnimation { duration: 1000 }}
    Behavior on height { HNumberAnimation {} }

    HRowLayout {
        HIcon {
            svgName: "uploading"
            colorize:
                status === "Error" ?  theme.colors.negativeBackground :
                status === "Paused" ?  theme.colors.middleBackground :
                theme.icons.colorize

            Layout.preferredWidth: theme.baseElementsHeight
            Layout.fillHeight: true
        }

        HLabel {
            id: statusLabel
            elide: expand ? Text.ElideNone : Text.ElideRight
            wrapMode: expand ? Text.Wrap : Text.NoWrap

            color: status === "Error" ?
                   theme.colors.errorText : theme.colors.text

            text:
                status === "Uploading" ? fileName :

                status === "Caching" ?
                qsTr("Caching %1...").arg(fileName) :

                model.error === "MatrixForbidden" ?
                qsTr("Forbidden file type or quota exceeded: %1")
                .arg(fileName) :

                model.error === "MatrixTooLarge" ?
                qsTr("Too large for this server: %1").arg(fileName) :

                model.error === "IsADirectoryError" ?
                qsTr("Can't upload folders, need a file: %1").arg(filePath) :

                model.error === "FileNotFoundError" ?
                qsTr("Non-existant file: %1").arg(filePath) :

                model.error === "PermissionError" ?
                qsTr("No permission to read this file: %1").arg(filePath) :

                qsTr("Unknown error for %1: %2 - %3")
                .arg(filePath).arg(model.error).arg(model.error_args)

            topPadding: theme.spacing / 2
            bottomPadding: topPadding
            leftPadding: theme.spacing / 1.5
            rightPadding: leftPadding

            Layout.fillWidth: true


            property bool expand: status === "Error"

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

        Repeater {
            model: [
                msLeft ? qsTr("-%1").arg(Utils.formatDuration(msLeft)) : "",

                speed ? qsTr("%1/s").arg(CppUtils.formattedBytes(speed)) : "",

                qsTr("%1/%2").arg(CppUtils.formattedBytes(uploaded))
                             .arg(CppUtils.formattedBytes(totalSize)),
            ]

            HLabel {
                text: modelData
                visible: text && Layout.preferredWidth > 0
                leftPadding: theme.spacing / 1.5
                rightPadding: leftPadding

                Layout.preferredWidth:
                    status === "Uploading" ? implicitWidth : 0

                Behavior on Layout.preferredWidth { HNumberAnimation {} }
            }
        }

        HButton {
            visible: Layout.preferredWidth > 0
            padded: false

            icon.name: transfer.paused ?
                       "upload-resume" : "upload-pause"

            icon.color: transfer.paused ?
                        theme.colors.positiveBackground :
                        theme.colors.middleBackground

            toolTip.text: transfer.paused ?
                          qsTr("Resume") : qsTr("Pause")

            onClicked: {
                transfer.guiPaused = ! transfer.guiPaused
                py.setattr(
                    model.monitor, "pause", transfer.guiPaused,
                )
            }

            Layout.preferredWidth:
                status === "Uploading" ?
                theme.baseElementsHeight : 0

            Layout.fillHeight: true

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }

        HButton {
            icon.name: "upload-cancel"
            icon.color: theme.colors.negativeBackground
            padded: false

            onClicked: {
                // Python might take a sec to cancel, but we want
                // immediate visual feedback
                transfer.height = 0
                // Python will delete this model item on cancel
                py.call(py.getattr(model.task, "cancel"))
            }

            Layout.preferredWidth: theme.baseElementsHeight
            Layout.fillHeight: true
        }
        TapHandler {
            onTapped: if (status !== "Error")
                statusLabel.expand = ! statusLabel.expand
        }
    }

    HProgressBar {
        id: progressBar
        visible: Layout.maximumHeight !== 0
        indeterminate: status !== "Uploading"
        value: uploaded
        to: totalSize

        // TODO: bake this in hprogressbar
        foregroundColor:
            status === "Error" ?
            theme.controls.progressBar.errorForeground :

            transfer.paused ?
            theme.controls.progressBar.pausedForeground :

            theme.controls.progressBar.foreground

        Layout.fillWidth: true
        Layout.maximumHeight:
            status === "Error" && indeterminate ? 0 : -1

        Behavior on Layout.maximumHeight { HNumberAnimation {} }
    }
}
