// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import CppUtils 0.1
import "../../Base"

Rectangle {
    property HPopup viewer
    property int maxTitleWidth: -1

    readonly property alias layout: layout
    readonly property alias title: title
    readonly property alias dimensions: dimensions
    readonly property alias fileSize: fileSize


    implicitHeight: Math.max(theme.baseElementsHeight, childrenRect.height)
    color: utils.hsluv(0, 0, 0, 0.8)

    Behavior on implicitHeight { HNumberAnimation {} }

    AutoDirectionLayout {
        id: layout
        width: parent.width - theme.spacing * 2
        anchors.horizontalCenter: parent.horizontalCenter
        columnSpacing: theme.spacing

        HLabel {
            id: title
            text: viewer.fullTitle
            elide: HLabel.ElideMiddle
            topPadding: layout.vertical ? theme.spacing / 2 : 0
            verticalAlignment: HLabel.AlignVCenter
            horizontalAlignment:
                layout.vertical ? HLabel.AlignHCenter : HLabel.AlignLeft

            Layout.fillWidth: maxTitleWidth < 0
            Layout.fillHeight: true
            Layout.maximumWidth: maxTitleWidth
        }

        HSpacer {
            visible: ! title.Layout.fillWidth
        }

        HLabel {
            id: dimensions
            text: qsTr("%1 x %2")
                  .arg(viewer.canvas.full.implicitWidth)
                  .arg(viewer.canvas.full.implicitHeight)

            elide: HLabel.ElideRight
            topPadding: theme.spacing / 2
            bottomPadding: topPadding
            horizontalAlignment: HLabel.AlignHCenter
            verticalAlignment: HLabel.AlignVCenter

            Layout.fillWidth: layout.vertical
            Layout.fillHeight: true
        }

        HLabel {
            id: fileSize
            visible: viewer.fullFileSize !== 0
            text: CppUtils.formattedBytes(viewer.fullFileSize)
            elide: HLabel.ElideRight
            horizontalAlignment: HLabel.AlignHCenter
            verticalAlignment: HLabel.AlignVCenter

            Layout.fillWidth: layout.vertical
            Layout.fillHeight: true
        }

        HLoader {
            source: "../../Base/HBusyIndicator.qml"
            visible: Layout.preferredWidth > 0
            active: viewer.canvas.full.showProgressBar

            Layout.topMargin: theme.spacing / 2
            Layout.bottomMargin: Layout.topMargin
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: active ? height : 0
            Layout.preferredHeight: theme.baseElementsHeight - theme.spacing

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }

        Item {
            visible: layout.vertical
            height: theme.spacing / 2
        }
    }
}
