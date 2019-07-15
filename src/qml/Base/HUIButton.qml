// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

HBaseButton {
    property int horizontalMargin: 0
    property int verticalMargin: 0

    property string iconName: ""
    property var iconDimension: null
    property var iconTransform: null

    property int fontSize: theme.fontSize.normal
    property bool centerText: Boolean(iconName)

    property bool loading: false

    property int contentWidth: 0

    readonly property alias visibility: button.visible
    onVisibilityChanged: if (! visibility) { loading = false }

    id: button

    Component {
        id: buttonContent

        HRowLayout {
            id: contentLayout
            spacing: button.text && iconName ? 8 : 0
            Component.onCompleted: contentWidth = implicitWidth

            HIcon {
                svgName: loading ? "hourglass" : iconName
                dimension: iconDimension || contentLayout.height
                transform: iconTransform
                opacity: button.enabled ? 1 : 0.7

                Layout.topMargin: verticalMargin
                Layout.bottomMargin: verticalMargin
                Layout.leftMargin: horizontalMargin
                Layout.rightMargin: horizontalMargin
            }

            HLabel {
                text: button.text
                font.pixelSize: fontSize
                horizontalAlignment: button.centerText ?
                                     Text.AlignHCenter : Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: enabled ?
                       theme.colors.foreground : theme.colors.foregroundDim2

                Layout.fillWidth: true
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
