import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

SwipeView {
    default property alias columnChildren: contentColumn.children

    property alias page: innerPage
    property alias header: innerPage.header
    property alias footer: innerPage.header
    property alias flickable: innerFlickable

    property alias headerLabel: innerHeaderLabel
    property var hideHeaderUnderHeight: null

    property int currentSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing)

    property bool becomeKeyboardFlickableTarget: true

    id: swipeView
    clip: true
    interactive: sidePane.reduce
    currentIndex: 1

    SidePane {
        implicitWidth: swipeView.width
        animateWidth: false  // Without this, the SidePane gets auto-focused
        collapse: false
        reduce: false
        visible: swipeView.interactive
        onVisibleChanged: if (currentIndex != 1) swipeView.setCurrentIndex(1)
    }

    Page {
        id: innerPage
        background: null

        header: Rectangle {
            implicitWidth: parent ? parent.width : 0
            color: theme.controls.header.background

            height: innerHeaderLabel.text && (
                ! hideHeaderUnderHeight ||
                window.height >=
                hideHeaderUnderHeight +
                theme.baseElementsHeight +
                currentSpacing * 2
            ) ?  theme.baseElementsHeight : 0

            Behavior on height { HNumberAnimation {} }
            visible: height > 0

            HLabel {
                id: innerHeaderLabel
                anchors.fill: parent
                textFormat: Text.StyledText
                font.pixelSize: theme.fontSize.big
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                leftPadding: currentSpacing
                rightPadding: leftPadding
            }
        }

        leftPadding: currentSpacing < theme.spacing ? 0 : currentSpacing
        rightPadding: leftPadding
        Behavior on leftPadding { HNumberAnimation {} }

        HFlickable {
            id: innerFlickable
            anchors.fill: parent
            clip: true
            contentWidth: parent.width
            contentHeight: contentColumn.childrenRect.height

            Component.onCompleted:
                if (becomeKeyboardFlickableTarget) shortcuts.flickTarget = this

            HColumnLayout {
                id: contentColumn
                width: innerFlickable.width
                height: innerFlickable.height
            }
        }
    }
}
