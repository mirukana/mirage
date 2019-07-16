// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

SwipeView {
    default property alias columnChildren: contentColumn.children
    property alias page: innerPage
    property alias flickable: innerFlickable

    property alias headerLabel: innerHeaderLabel
    property var hideHeaderUnderHeight: null

    property bool wide: width > 414 + leftPadding + rightPadding

    property int currentSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing * 2)

    id: swipeView
    currentIndex: 1
    clip: true
    interactive: sidePane.reduce

    SidePane {
        canAutoSize: false
        autoWidthRatio: 1.0
        visible: swipeView.interactive
        onVisibleChanged: swipeView.setCurrentIndex(1)
    }

    Page {
        id: innerPage
        background: null

        header: HRectangle {
            width: parent.width
            implicitWidth: parent.width
            color: theme.pageHeadersBackground

            height: ! hideHeaderUnderHeight ||
                    window.height >=
                    hideHeaderUnderHeight +
                    theme.baseElementsHeight +
                    currentSpacing * 2 ?
                    theme.baseElementsHeight : 0

            Behavior on height { HNumberAnimation {} }
            visible: height > 0

            HRowLayout {
                width: parent.width

                HLabel {
                    id: innerHeaderLabel
                    text: qsTr("Account settings for %1").arg(
                        Utils.coloredNameHtml(userInfo.displayName, userId)
                    )
                    textFormat: Text.StyledText
                    font.pixelSize: theme.fontSize.big
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter

                    Layout.leftMargin: currentSpacing
                    Layout.rightMargin: Layout.leftMargin
                    Layout.fillWidth: true
                }
            }
        }

        leftPadding: currentSpacing < theme.spacing ? 0 : currentSpacing
        rightPadding: leftPadding
        Behavior on leftPadding { HNumberAnimation {} }

        Flickable {
            id: innerFlickable
            anchors.fill: parent
            clip: true
            contentWidth: parent.width
            contentHeight: contentColumn.childrenRect.height
            interactive: contentWidth > width || contentHeight > height

            HColumnLayout {
                id: contentColumn
                spacing: theme.spacing
                width: innerFlickable.width
                height: innerFlickable.height
            }
        }
    }
}
