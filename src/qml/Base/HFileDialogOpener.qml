// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import Qt.labs.platform 1.1

Item {
    anchors.fill: parent

    property alias dialog: fileDialog
    property var selectedFile: null

    enum FileType { All, Images }
    property int fileType: FileType.All

    TapHandler { onTapped: fileDialog.open() }

    FileDialog {
        id: fileDialog

        property var filters: ({
            all:    qsTr("All files") + " (*)",
            images: qsTr("Image files") +
                    " (*.jpg *.jpeg *.png *.gif *.bmp *.webp)"
        })

        nameFilters:
            fileType == HFileDialogOpener.FileType.Images ?
            [filters.images, filters.all] :
            [filters.all]

            folder: StandardPaths.writableLocation(
                fileType == HFileDialogOpener.FileType.Images ?
                StandardPaths.PicturesLocation :
                StandardPaths.HomeLocation
            )

        title: "Select file"
        modality: Qt.WindowModal

        onVisibleChanged: if (visible) {
            selectedFile = Qt.binding(() => Qt.resolvedUrl(currentFile))
        }
        onRejected: selectedFile = null
    }
}
