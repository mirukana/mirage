import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.7
import QtGraphicalEffects 1.12
import "Base"
import "MainPane"

Item {
    id: mainUI
    focus: true
    Component.onCompleted: window.mainUI = mainUI

    readonly property alias shortcuts: shortcuts
    readonly property alias mainPane: mainPane
    readonly property alias pageLoader: pageLoader
    readonly property alias pressAnimation: pressAnimation
    readonly property alias fullScreenPopup: fullScreenPopup

    SequentialAnimation {
        id: pressAnimation
        HNumberAnimation {
            target: mainUI; property: "scale";  from: 1.0; to: 0.9
        }
        HNumberAnimation {
            target: mainUI; property: "scale";  from: 0.9; to: 1.0
        }
    }

    property bool accountsPresent:
        (modelSources["Account"] || []).length > 0 ||
        py.startupAnyAccountsSaved

    Shortcuts { id: shortcuts }

    HImage {
        id: mainUIBackground
        visible: Boolean(Qt.resolvedUrl(source))
        fillMode: Image.PreserveAspectCrop
        source: theme.ui.image
        sourceSize.width: Screen.width
        sourceSize.height: Screen.height
        anchors.fill: parent
        asynchronous: false
    }

    LinearGradient {
        id: mainUIGradient
        anchors.fill: parent
        start: theme.ui.gradientStart
        end: theme.ui.gradientEnd

        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.ui.gradientStartColor }
            GradientStop { position: 1.0; color: theme.ui.gradientEndColor }
        }
    }


    MainPane {
        id: mainPane
    }

    HLoader {
        id: pageLoader
        anchors.fill: parent
        anchors.leftMargin: mainPane.visibleSize
        visible: ! mainPane.hidden || anchors.leftMargin < width
        clip: appearAnimation.running
        onLoaded: { takeFocus(); appearAnimation.start() }
        // onSourceChanged: if (mainPane.collapse) mainPane.close()


        property bool isWide: width > theme.contentIsWideAbove

        // List of previously loaded [componentUrl, {properties}]
        property var history: []
        property int historyLength: 20

        Component.onCompleted: {
            if (! py.startupAnyAccountsSaved) {
                pageLoader.showPage("AddAccount/AddAccount")
                return
            }

            let page  = window.uiState.page
            let props = window.uiState.pageProperties

            if (page === "Chat/Chat.qml") {
                pageLoader.showRoom(props.userId, props.roomId)
            } else {
                pageLoader._show(page, props)
            }
        }

        function _show(componentUrl, properties={}) {
            history.unshift([componentUrl, properties])
            if (history.length > historyLength) history.pop()

            pageLoader.setSource(componentUrl, properties)
        }

        function showPage(name, properties={}) {
            let path = `Pages/${name}.qml`
            _show(path, properties)

            window.uiState.page           = path
            window.uiState.pageProperties = properties
            window.uiStateChanged()
        }

        function showRoom(userId, roomId) {
            _show("Chat/Chat.qml", {userId, roomId})

            window.uiState.page           = "Chat/Chat.qml"
            window.uiState.pageProperties = {userId, roomId}
            window.uiStateChanged()
        }

        function showPrevious(timesBack=1) {
            timesBack = Math.min(timesBack, history.length - 1)
            if (timesBack < 1) return false

            let [componentUrl, properties] = history[timesBack]

            _show(componentUrl, properties)

            window.uiState.page           = componentUrl
            window.uiState.pageProperties = properties
            window.uiStateChanged()
            return true
        }

        function takeFocus() {
            pageLoader.item.forceActiveFocus()
            if (mainPane.collapse) mainPane.close()
        }


        HNumberAnimation {
            id: appearAnimation
            target: pageLoader.item
            property: "x"
            from: -300
            to: 0
            easing.type: Easing.OutBack
            duration: theme.animationDuration * 2
        }
    }

    HPopup {
        id: fullScreenPopup
        dim: false
        width: window.width
        height: window.height
    }
}
