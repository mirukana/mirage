import QtQuick 2.13
import QtQuick.Controls 2.13
import "../utils.js" as Utils

Drawer {
    id: drawer
    x: horizontal ? 0 : referenceSizeParent.width / 2 - width / 2
    y: vertical ? 0 : referenceSizeParent.height / 2 - height / 2
    implicitWidth: horizontal ? calculatedSize : referenceSizeParent.width
    implicitHeight: vertical ? calculatedSize : referenceSizeParent.height

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

    property int normalSize:
        horizontal ? referenceSizeParent.width : referenceSizeParent.height
    property int minNormalSize: resizeAreaSize
    property int maxNormalSize:
        horizontal ?
        referenceSizeParent.width - theme.minimumSupportedWidth :
        referenceSizeParent.height - theme.minimumSupportedHeight

    property bool collapse:
        (horizontal ? window.width : window.height) < 400
    property int collapseExpandSize:
        horizontal ? referenceSizeParent.width : referenceSizeParent.height

    property int resizeAreaSize: theme.spacing / 2

    readonly property int calculatedSize:
        collapse ?
        collapseExpandSize :
        Math.max(minNormalSize, Math.min(normalSize, maxNormalSize))

    readonly property bool horizontal:
        edge === Qt.LeftEdge || edge === Qt.RightEdge

    readonly property bool vertical: ! horizontal


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
        y: horizontal || drawer.edge !== Qt.TopEdge ? 0 : drawer.height-height
        width: horizontal ? resizeAreaSize : parent.width
        height: vertical ? resizeAreaSize : parent.height
        z: 999

        MouseArea {
            id: resizeMouseHandler
            anchors.fill: parent
            enabled: ! drawer.collapse
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape:
                containsMouse || drag.active ?
                (horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor) :
                Qt.ArrowCursor

            onPressed: canResize = true
            onReleased: { canResize = false; userResized(drawer.normalSize) }

            onMouseXChanged:
                if (horizontal && canResize) {
                    drawer.normalSize =
                        drawer.calculatedSize +
                        (drawer.edge === Qt.RightEdge ? -mouseX : mouseX)
                }

            onMouseYChanged:
                if (vertical && canResize) {
                    drawer.normalSize =
                        drawer.calculatedSize +
                        (drawer.edge === Qt.BottomEdge ? -mouseY : mouseY)
                }

            property bool canResize: false
        }
    }
}
