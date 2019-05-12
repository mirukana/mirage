import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

HRectangle {
    id: roomSidePane

    property bool collapsed: false

    HColumnLayout {
        anchors.fill: parent

        MembersView {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
