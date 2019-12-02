// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HListView {
    id: accordion


    property Component category
    property Component content
    property Component expander: HButton {
        id: expanderItem
        iconItem.small: true
        icon.name: "expand"
        backgroundColor: "transparent"
        toolTip.text: expand ? qsTr("Collapse") : qsTr("Expand")
        onClicked: expand = ! expand

        leftPadding: theme.spacing / 2
        rightPadding: leftPadding

        iconItem.transform: Rotation {
            origin.x: expanderItem.iconItem.width / 2
            origin.y: expanderItem.iconItem.height / 2
            angle: expanderItem.loading ? 0 : expand ? 90 : 180

            Behavior on angle { HNumberAnimation {} }
        }

        Behavior on opacity { HNumberAnimation {} }
    }


    delegate: HColumnLayout {
        id: categoryContentColumn
        width: accordion.width

        property bool expand: true
        readonly property QtObject categoryModel: model

        HRowLayout {
            Layout.fillWidth: true

            HLoader {
                id: categoryLoader
                sourceComponent: category

                Layout.fillWidth: true

                readonly property QtObject model: categoryModel
            }
            HLoader {
                sourceComponent: expander

                readonly property QtObject model: categoryModel
                property alias expand: categoryContentColumn.expand
            }
        }

        Item {
            opacity: expand ? 1 : 0
            visible: opacity > 0

            Layout.fillWidth: true
            Layout.preferredHeight: contentLoader.implicitHeight * opacity

            Behavior on opacity { HNumberAnimation {} }

            HLoader {
                id: contentLoader
                width: parent.width
                active: categoryLoader.status === Loader.Ready
                sourceComponent: content

                readonly property QtObject xcategoryModel: categoryModel
            }
        }
    }
}
