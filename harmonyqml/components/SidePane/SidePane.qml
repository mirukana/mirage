import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import "../Base" as Base

Base.HGlassRectangle {
    id: sidePane
    clip: true  // Avoid artifacts when resizing pane width to minimum

    isPageStackDescendant: false

    Base.HColumnLayout {
        anchors.fill: parent

        AccountList {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        PaneToolBar {}
    }
}
