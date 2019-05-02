import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import "../Base"

HGlassRectangle {
    id: sidePane
    isPageStackDescendant: false

    HColumnLayout {
        anchors.fill: parent

        AccountList {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.leftMargin:
                sidePane.width <= (sidePane.Layout.minimumWidth + spacing) ?
                0 : spacing
        }

        PaneToolBar {}
    }
}
