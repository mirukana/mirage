import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

Column {
    id: roomCategoryDelegate
    width: roomCategoriesList.width

    property int normalHeight: childrenRect.height  // avoid binding loop

    height: roomList.model.count > 0 ? normalHeight : 0
    visible: roomList.model.count > 0

    property string roomListUserId: userId
    property bool expanded: true

    HRowLayout {
        width: parent.width

        HLabel {
            id: roomCategoryLabel
            text: name
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1

            Layout.fillWidth: true
        }

        ExpandButton {
            expandableItem: roomCategoryDelegate
        }
    }

    RoomList {
        id: roomList
        interactive: false  // no scrolling
        visible: height > 0
        width: roomCategoriesList.width - accountList.Layout.leftMargin
        height: childrenRect.height * (roomCategoryDelegate.expanded ? 1 : 0)
        clip: heightAnimation.running

        userId: roomListUserId
        category: name

        Behavior on height {
            NumberAnimation {
                id: heightAnimation
                duration: HStyle.animationDuration
            }
        }
    }
}
