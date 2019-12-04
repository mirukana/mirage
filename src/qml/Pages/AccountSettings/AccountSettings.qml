import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HPage {
    id: accountSettings

    property int avatarPreferredSize: 256 * theme.uiScale

    property string userId: ""

    readonly property bool ready:
        accountInfo !== "waiting" && Boolean(accountInfo.profile_updated)

    readonly property var accountInfo: Utils.getItem(
        modelSources["Account"] || [], "user_id", userId
    ) || "waiting"

    property string headerName: ready ? accountInfo.display_name : userId

    hideHeaderUnderHeight: avatarPreferredSize
    headerLabel.text: qsTr("Account settings for %1").arg(
        Utils.coloredNameHtml(headerName, userId)
    )


    HSpacer {}

    Repeater {
        id: repeater
        model: ["Profile.qml", "ImportExportKeys.qml"]

        Rectangle {
            color: ready ? theme.controls.box.background : "transparent"
            Behavior on color { HColorAnimation {} }

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: header.visible || index > 0 ? theme.spacing : 0
            Layout.bottomMargin:
                header.visible || index < repeater.count - 1? theme.spacing : 0

            Layout.maximumWidth: Math.min(parent.width, 640)
            Layout.preferredWidth:
                pageLoader.isWide ? parent.width : avatarPreferredSize

            Layout.preferredHeight: childrenRect.height

            HLoader {
                anchors.centerIn: parent
                width: ready ? parent.width : 96
                source: ready ?
                        modelData :
                        (modelData == "Profile.qml" ?
                         "../../Base/HBusyIndicator.qml" : "")
            }
        }
    }

    HSpacer {}
}
