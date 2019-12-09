import QtQuick 2.13
import QtQuick.Controls 2.13
import "../utils.js" as Utils

Drawer {
    id: drawer
    x: vertical ? referenceSizeParent.width / 2 - width / 2 : 0
    y: vertical ? 0 : referenceSizeParent.height / 2 - height / 2
    implicitWidth: vertical ? referenceSizeParent.width : calculatedWidth
    implicitHeight: vertical ? calculatedWidth : referenceSizeParent.height

    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    // FIXME: https://bugreports.qt.io/browse/QTBUG-59141
    // dragMargin: parent.width / 2

    interactive: collapse
    position: 1
    visible: ! collapse
    modal: false
    closePolicy: Popup.CloseOnEscape

    background: Rectangle { id: bg; color: theme.colors.strongBackground }


    signal userResized(int newWidth)

    property alias color: bg.color

    property Item referenceSizeParent: parent

    property int normalWidth:
        vertical ? referenceSizeParent.height : referenceSizeParent.width
    property int minNormalWidth: resizeAreaWidth
    property int maxNormalWidth:
        vertical ?
        referenceSizeParent.height - theme.minimumSupportedHeight :
        referenceSizeParent.width - theme.minimumSupportedWidth

    property bool collapse:
        (vertical ? window.height : window.width) < 400
    property int collapseExpandedWidth:
        vertical ? referenceSizeParent.height : referenceSizeParent.width

    property int resizeAreaWidth: theme.spacing / 2

    readonly property int calculatedWidth:
        collapse ?
        collapseExpandedWidth :
        Math.max(minNormalWidth, Math.min(normalWidth, maxNormalWidth))

    readonly property bool vertical:
        edge === Qt.TopEdge || edge === Qt.BottomEdge


    Behavior on width {
        enabled: ! resizeMouseHandler.drag.active
        NumberAnimation { duration: 100 }
    }

    Behavior on height {
        enabled: ! resizeMouseHandler.drag.active
        NumberAnimation { duration: 100 }
    }

    Item {
        id: resizeArea
        x: vertical || drawer.edge === Qt.RightEdge ? 0 : drawer.width-width
        y: ! vertical || drawer.edge !== Qt.TopEdge ? 0 : drawer.height-height
        width: vertical ? parent.width : resizeAreaWidth
        height: vertical ? resizeAreaWidth : parent.height
        z: 999

        MouseArea {
            id: resizeMouseHandler
            anchors.fill: parent
            enabled: ! drawer.collapse
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape:
                containsMouse || drag.active ?
                (vertical ? Qt.SizeVerCursor : Qt.SizeHorCursor) :
                Qt.ArrowCursor

            onPressed: canResize = true
            onReleased: { canResize = false; userResized(drawer.normalWidth) }

            onMouseXChanged:
                if (! vertical && canResize) {
                    drawer.normalWidth =
                        drawer.calculatedWidth +
                        (drawer.edge === Qt.RightEdge ? -mouseX : mouseX)
                }

            onMouseYChanged:
                if (vertical && canResize) {
                    drawer.normalWidth =
                        drawer.calculatedWidth +
                        (drawer.edge === Qt.BottomEdge ? -mouseY : mouseY)
                }

            property bool canResize: false
        }
    }
}
