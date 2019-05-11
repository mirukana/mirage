import QtQuick.Layouts 1.3
import "../Base"

HRectangle {
    id: sidePane

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
