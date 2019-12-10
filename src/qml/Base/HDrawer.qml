import QtQuick 2.13
import QtQuick.Controls 2.13
import "../utils.js" as Utils

Drawer {
    id: drawer
    implicitWidth: horizontal ? calculatedSize : parent.width
    implicitHeight: vertical ? calculatedSize : parent.height

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


    property alias color: bg.color

    property int defaultSize: 300

    property int preferredSize:
        window.uiState[objectName] ?
        (window.uiState[objectName].size || defaultSize) :
        defaultSize

    property int minimumSize: resizeAreaSize
    property int maximumSize:
        horizontal ?
        referenceSizeParent.width - theme.minimumSupportedWidth :
        referenceSizeParent.height - theme.minimumSupportedHeight

    //

    property Item referenceSizeParent: parent

    property bool collapse:
        (horizontal ? window.width : window.height) < 400
    property int peekSizeWhileCollapsed:
        horizontal ? referenceSizeParent.width : referenceSizeParent.height

    property int resizeAreaSize: theme.spacing / 2

    readonly property int calculatedSize:
        collapse ?
        peekSizeWhileCollapsed :
        Math.max(minimumSize, Math.min(preferredSize, maximumSize))

    //

    readonly property int visibleSize: visible ? width * position : 0

    readonly property bool horizontal:
        edge === Qt.LeftEdge || edge === Qt.RightEdge

    readonly property bool vertical: ! horizontal


    Behavior on width {
        enabled: horizontal && ! resizeMouseHandler.drag.active
        NumberAnimation { duration: 100 }
    }

    Behavior on height {
        enabled: vertical && ! resizeMouseHandler.drag.active
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

            onMouseXChanged:
                if (horizontal && pressed) {
                    drawer.preferredSize =
                        drawer.calculatedSize +
                        (drawer.edge === Qt.RightEdge ? -mouseX : mouseX)
                }

            onMouseYChanged:
                if (vertical && pressed) {
                    drawer.preferredSize =
                        drawer.calculatedSize +
                        (drawer.edge === Qt.BottomEdge ? -mouseY : mouseY)
                }

            onReleased: {
                if (! drawer.objectName) {
                    console.warn("Can't save pane size, no objectName set")
                    return
                }

                window.uiState[drawer.objectName] = {
                    size: drawer.preferredSize,
                }
                window.uiStateChanged()
            }
        }
    }
}
