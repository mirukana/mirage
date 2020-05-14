// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Drawer {
    id: drawer
    implicitWidth: horizontal ? calculatedSize : parent.width
    implicitHeight: vertical ? calculatedSize : parent.height

    // Prevents this: open a popup, make the window small enough for the
    // drawer to collapse, then make it big again → popup is now behind drawer
    z: -1

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
    closePolicy: Popup.NoAutoClose

    background: Rectangle { id: bg; color: theme.colors.strongBackground }


    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["preferredSize"]

    //

    property alias color: bg.color

    property int defaultSize: 300 * theme.uiScale

    property int preferredSize:
        window.getState(this, "preferredSize", defaultSize)

    property int minimumSize: resizeAreaSize
    property int maximumSize:
        horizontal ? referenceSizeParent.width : referenceSizeParent.height

    property int snapAt: defaultSize
    property int snapZone: theme.spacing * 2

    //

    property Item referenceSizeParent: parent

    property bool collapse:
        (horizontal ? window.width : window.height) <
        window.settings.collapseSidePanesUnderWindowWidth * theme.uiScale

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
        width: horizontal ? resizeAreaSize * theme.uiScale : parent.width
        height: vertical ? resizeAreaSize * theme.uiScale : parent.height
        z: 999

        MouseArea {
            id: resizeMouseHandler
            anchors.fill: parent
            enabled: ! drawer.collapse
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: true
            cursorShape:
                containsMouse || drag.active ?
                (horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor) :
                Qt.ArrowCursor

            onMouseXChanged:
                if (horizontal && pressed) {
                    drawer.preferredSize = snapSize(
                        drawer.calculatedSize +
                        (drawer.edge === Qt.RightEdge ? -mouseX : mouseX)
                    )
                }

            onMouseYChanged:
                if (vertical && pressed) {
                    drawer.preferredSize = snapSize(
                        drawer.calculatedSize +
                        (drawer.edge === Qt.BottomEdge ? -mouseY : mouseY)
                    )
                }

            onReleased: window.saveState(drawer)

            function snapSize(num) {
                return num < snapAt + snapZone && num  > snapAt - snapZone ?
                       snapAt : num
            }
        }
    }
}
