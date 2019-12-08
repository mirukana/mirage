import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../SidePane"

Page {
    id: innerPage


    default property alias columnChildren: contentColumn.children

    property alias flickable: innerFlickable
    property alias headerLabel: innerHeaderLabel
    property var hideHeaderUnderHeight: null

    property int currentSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing)

    property bool becomeKeyboardFlickableTarget: true


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
