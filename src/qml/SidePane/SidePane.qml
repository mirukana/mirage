import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HRectangle {
    id: sidePane

    property int normalSpacing: 8
    property bool collapsed: false

    HColumnLayout {
        anchors.fill: parent

        AccountList {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: collapsed ? 0 : normalSpacing * 3
            topMargin: collapsed ? 0 : normalSpacing
            bottomMargin: topMargin
            Layout.leftMargin: topMargin

            Behavior on spacing { HNumberAnimation {} }
        }

        PaneToolBar {
            id: paneToolBar
        }
    }
}
