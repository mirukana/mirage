import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.7
import "Base"
import "SidePane"

HRectangle {
    id: mainUI
    color: theme.ui.background
    Component.onCompleted: window.mainUI = mainUI

    property alias pressAnimation: _pressAnimation

    SequentialAnimation {
        id: _pressAnimation
        HNumberAnimation {
            target: mainUI; property: "scale"; from: 1.0; to: 0.9
        }
        HNumberAnimation {
            target: mainUI; property: "scale"; from: 0.9; to: 1.0
        }
    }

    property bool accountsPresent:
        (modelSources["Account"] || []).length > 0 ||
        py.startupAnyAccountsSaved

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

    HSplitView {
        id: uiSplitView
        anchors.fill: parent

        onAnyResizingChanged: if (anyResizing) {
            sidePane.manuallyResizing = true
        } else {
            sidePane.manuallyResizing = false
            sidePane.manuallyResized = true
            sidePane.manualWidth = sidePane.width
        }

        SidePane {
            id: sidePane

            // Initial width until user manually resizes
            width: implicitWidth
            Layout.minimumWidth: reduce ? 0 : theme.sidePane.collapsedWidth
            Layout.maximumWidth:
                window.width - theme.minimumSupportedWidthPlusSpacing

            Behavior on Layout.minimumWidth { HNumberAnimation {} }
        }

        StackView {
            id: pageStack
            property bool isWide: width > theme.contentIsWideAbove

            Component.onCompleted: {
                if (! py.startupAnyAccountsSaved) {
                    pageStack.showPage("SignIn")
                    return
                }

                let page  = window.uiState.page
                let props = window.uiState.pageProperties

                if (page == "Chat/Chat.qml") {
                    pageStack.showRoom(props.userId, props.roomId)
                } else {
                    pageStack.show(page, props)
                }
            }

            function show(componentUrl, properties={}) {
                pageStack.replace(componentUrl, properties)
            }

            function showPage(name, properties={}) {
                let path = "Pages/" + name + ".qml"
                show(path, properties)

                window.uiState.page           = path
                window.uiState.pageProperties = properties
                window.uiStateChanged()
            }

            function showRoom(userId, roomId) {
                show("Chat/Chat.qml", {userId, roomId})

                window.uiState.page           = "Chat/Chat.qml"
                window.uiState.pageProperties = {userId, roomId}
                window.uiStateChanged()
            }

            onCurrentItemChanged: if (currentItem) {
                currentItem.forceActiveFocus()
            }

            // Buggy
            replaceExit: null
            popExit: null
            pushExit: null
        }
    }
}
