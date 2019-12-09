import QtQuick 2.13
import QtQuick.Controls 2.13
import "../utils.js" as Utils

Drawer {
    id: drawer
    implicitWidth: calculatedWidth
    implicitHeight: referenceSizeParent.height

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

    property Item referenceSizeParent: parent

    property int normalWidth: 300
    property int minNormalWidth: resizeAreaWidth
    property int maxNormalWidth:
        referenceSizeParent.width - theme.minimumSupportedWidth

    property bool collapse: window.width < 400
    property int collapseExpandedWidth: referenceSizeParent.width

    property alias color: bg.color
    property alias resizeAreaWidth: resizeArea.width

    readonly property int calculatedWidth:
        collapse ?
        collapseExpandedWidth :
        Math.max(minNormalWidth, Math.min(normalWidth, maxNormalWidth))


    Behavior on width {
        enabled: ! resizeMouseHandler.drag.active
        NumberAnimation { duration: 100 }
    }

    Item {
        id: resizeArea
        x: drawer.edge === Qt.LeftEdge ? drawer.width - width : 0
        width: theme.spacing / 2
        height: parent.height
        z: 9999

        MouseArea {
            id: resizeMouseHandler
            anchors.fill: parent
            enabled: ! drawer.collapse
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape:
                containsMouse || drag.active ?
                Qt.SizeHorCursor : Qt.ArrowCursor

            onPressed: canResize = true
            onReleased: { canResize = false; userResized(drawer.normalWidth) }

            onMouseXChanged:
                if (canResize) {
                    drawer.normalWidth =
                        drawer.calculatedWidth +
                        (drawer.edge === Qt.RightEdge ? -mouseX : mouseX)
                }

            property bool canResize: false
        }
    }
}
