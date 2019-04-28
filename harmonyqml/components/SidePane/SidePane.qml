import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import "../Base"

HGlassRectangle {
    id: sidePane
    clip: true  // Avoid artifacts when resizing pane width to minimum

    isPageStackDescendant: false

    HColumnLayout {
        anchors.fill: parent

        AccountList {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        PaneToolBar {}
    }
}
