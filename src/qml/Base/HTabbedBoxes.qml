import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

HColumnLayout {
    implicitWidth: Math.min(
        parent.width,
        Math.max(tabBar.contentWidth, swipeView.contentWidth),
    )

    Layout.alignment: Qt.AlignCenter
    Layout.fillWidth: false
    Layout.fillHeight: false

    property alias tabIndex: tabBar.currentIndex
    property alias tabModel: tabRepeater.model
    default property alias boxes: swipeView.contentData

    HTabBar {
        id: tabBar
        Component.onCompleted: shortcuts.tabsTarget = this

        Layout.fillWidth: true

        Repeater {
            id: tabRepeater
            HTabButton { text: modelData }
        }
    }

    SwipeView {
        id: swipeView
        clip: true
        currentIndex: tabBar.currentIndex
        interactive: false

        Layout.fillWidth: true

        Behavior on implicitWidth { HNumberAnimation {} }
        Behavior on implicitHeight { HNumberAnimation {} }
    }
}
