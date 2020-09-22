// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/HTile"

HTile {
    id: root

    property string loadingIconStep


    backgroundColor: "transparent"
    contentOpacity: model.status === "Failed" ? 0.3 : 1  // XXX
    rightPadding: 0
    compact: false

    contentItem: ContentRow {
        tile: root
        spacing: 0

        HIcon {
            id: signalIcon

            svgName:
                model.status === "Failed" ? "server-ping-fail" :
                model.status === "Pinging" ? root.loadingIconStep :
                model.ping < 400 ? "server-ping-good" :
                model.ping < 800 ? "server-ping-medium" :
                "server-ping-bad"

            colorize:
                model.status === "Failed" ? theme.colors.negativeBackground :
                model.status === "Pinging" ? theme.colors.accentBackground :
                model.ping < 400 ? theme.colors.positiveBackground :
                model.ping < 800 ? theme.colors.middleBackground :
                theme.colors.negativeBackground

            Layout.fillHeight: true
            Layout.rightMargin: theme.spacing

            Behavior on colorize { HColorAnimation {} }

            HoverHandler { id: iconHover }

            HToolTip {
                visible: iconHover.hovered
                text:
                    model.status === "Failed" ? qsTr("Connection failed") :
                    model.status === "Pinging" ? qsTr("Contacting...") :
                    qsTr("%1ms").arg(model.ping)
            }
        }

        HColumnLayout {
            Layout.rightMargin: theme.spacing

            TitleLabel {
                text: model.name
            }

            SubtitleLabel {
                tile: root
                text: model.country
            }
        }

        TitleRightInfoLabel {
            tile: root
            font.pixelSize: theme.fontSize.normal

            text:
                model.stability === -1 ?
                "" :
                qsTr("%1%").arg(Math.max(0, parseInt(model.stability, 10)))

            color:
                model.stability >= 95 ? theme.colors.positiveText :
                model.stability >= 85 ? theme.colors.warningText :
                theme.colors.errorText
        }

        HButton {
            icon.name: "server-visit-website"
            backgroundColor: "transparent"
            onClicked: Qt.openUrlExternally(model.site_url)

            Layout.fillHeight: true
        }
    }

    Behavior on contentOpacity { HNumberAnimation {} }

    DelegateTransitionFixer {}
}
