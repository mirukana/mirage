// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import CppUtils 0.1
import "../../../Base"

HColumnLayout {
    id: transfer

    property bool cancelPending: false

    property int msLeft: model.time_left
    property int uploaded: model.uploaded
    readonly property int speed: model.speed
    readonly property int totalSize: model.total_size
    readonly property string status: model.status
    readonly property bool paused: model.paused

    function cancel() {
        cancelPending = true
        // Python will delete this model item on cancel
        py.callClientCoro(chat.userId, "cancel_upload", [model.id])
    }

    function toggle_pause() {
        py.callClientCoro(
            chat.userId, "toggle_pause_upload", [chat.roomId, model.id],
        )
    }


    Behavior on height { HNumberAnimation {} }

    HRowLayout {
        HIcon {
            svgName: "uploading"
            colorize:
                cancelPending || transfer.status === "Error" ?
                theme.colors.negativeBackground :

                transfer.paused ?
                theme.colors.middleBackground :

                theme.icons.colorize

            Layout.preferredWidth: theme.baseElementsHeight
        }

        HLabel {
            id: statusLabel

            property bool expand: status === "Error"

            readonly property string fileName:
                model.filepath.split("/").slice(-1)[0]

            readonly property string filePath:
                model.filepath.replace(/^file:\/\//, "")

            elide: expand ? Text.ElideNone : Text.ElideRight
            wrapMode: expand ? Text.Wrap : Text.NoWrap

            text:
                cancelPending ?
                qsTr("Cancelling...") :

                status === "Uploading" ?
                fileName :

                status === "Caching" ?
                qsTr("Caching %1...").arg(fileName) :

                model.error === "MatrixForbidden" ?
                qsTr("Forbidden file type or quota exceeded: %1")
                .arg(fileName) :

                model.error === "MatrixTooLarge" ?
                qsTr("Too large for this server (%1 max): %2")
                .arg(CppUtils.formattedBytes(chat.userInfo.max_upload_size))
                .arg(fileName) :

                model.error === "IsADirectoryError" ?
                qsTr("Can't upload folders, need a file: %1").arg(filePath) :

                model.error === "FileNotFoundError" ?
                qsTr("Non-existent file: %1").arg(filePath) :

                model.error === "PermissionError" ?
                qsTr("No permission to read this file: %1").arg(filePath) :

                qsTr("Unknown error for %1: %2 - %3")
                .arg(filePath).arg(model.error).arg(model.error_args)

            topPadding: theme.spacing / 2
            bottomPadding: topPadding
            leftPadding: theme.spacing / 1.5
            rightPadding: leftPadding

            Layout.fillWidth: true

            HoverHandler { id: statusLabelHover }

            HToolTip {
                text: parent.truncated ? parent.text : ""
                visible: text && statusLabelHover.hovered
            }
        }

        HSpacer {}

        Repeater {
            model: [
                msLeft ? qsTr("-%1").arg(utils.formatDuration(msLeft)) : "",

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

            onClicked: transfer.toggle_pause()

            Layout.preferredWidth:
                status === "Uploading" ?
                theme.baseElementsHeight : 0

            Layout.fillHeight: true

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }

        HButton {
            icon.name: "upload-cancel"
            icon.color: theme.colors.negativeBackground
            onClicked: transfer.cancel()
            padded: false

            Layout.preferredWidth: theme.baseElementsHeight
            Layout.fillHeight: true
        }

        TapHandler {
            onTapped: {
                if (status === "Error") { transfer.cancel() }
                else { statusLabel.expand = ! statusLabel.expand }
            }
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
            cancelPending || status === "Error" ?
            theme.controls.progressBar.errorForeground :

            transfer.paused ?
            theme.controls.progressBar.pausedForeground :

            theme.controls.progressBar.foreground

        Layout.fillWidth: true
        Layout.maximumHeight:
            status === "Error" && indeterminate ? 0 : -1

        Behavior on value { HNumberAnimation { duration: 1200 } }
        Behavior on Layout.maximumHeight { HNumberAnimation {} }
    }
}
