import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Base.HToolButton {
    function toolBarIsBig() {
        return sidePane.width >
               Layout.minimumWidth * (toolBar.children.length - 2)
    }

    id: "button"
    visible: toolBarIsBig()
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.minimumWidth: height
}
