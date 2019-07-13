// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HBaseButton {
    property int horizontalMargin: 0
    property int verticalMargin: 0

    property string iconName: ""
    property var iconDimension: null
    property var iconTransform: null

    property int fontSize: theme.fontSize.normal

    property bool loading: false

    property int contentWidth: 0

    readonly property alias visibility: button.visible
    onVisibilityChanged: if (! visibility) { loading = false }

    id: button

    Component {
        id: buttonContent

        HRowLayout {
            id: contentLayout
            spacing: button.text && iconName ? 5 : 0
            Component.onCompleted: contentWidth = implicitWidth

            HIcon {
                svgName: loading ? "hourglass" : iconName
                dimension: iconDimension || contentLayout.height
                transform: iconTransform

                Layout.topMargin: verticalMargin
                Layout.bottomMargin: verticalMargin
                Layout.leftMargin: horizontalMargin
                Layout.rightMargin: horizontalMargin
            }

            HLabel {
                text: button.text
                font.pixelSize: fontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }

    Component {
        id: loadingOverlay
        HRowLayout {
            HIcon {
                svgName: "hourglass"
                Layout.preferredWidth: contentWidth || -1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }

    contentItem: Loader {
        sourceComponent:
            loading && ! iconName ? loadingOverlay : buttonContent
    }
}
