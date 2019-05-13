import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Button {
    property int horizontalMargin: 0
    property int verticalMargin: 0

    property string iconName: ""
    property var iconDimension: null
    property var iconTransform: null
    property bool circle: false

    property int fontSize: HStyle.fontSize.normal
    property color backgroundColor: HStyle.controls.button.background
    property alias overlayOpacity: buttonBackgroundOverlay.opacity
    property bool checkedLightens: false

    property bool loading: false

    property int contentWidth: 0

    readonly property alias visibility: button.visible
    onVisibilityChanged: if (! visibility) { loading = false }

    signal canceled
    signal clicked
    signal doubleClicked
    signal entered
    signal exited
    signal pressAndHold
    signal pressed
    signal released

    function loadingUntilFutureDone(future) {
        loading = true
        future.onGotResult.connect(function() { loading = false })
    }

    id: button

    background: Rectangle {
        id: buttonBackground
        color: Qt.lighter(
            backgroundColor, checked ? (checkedLightens ? 1.3 : 0.7) : 1.0
        )
        radius: circle ? height : 0

        Behavior on color {
            ColorAnimation { duration: 60 }
        }

        Rectangle {
            id: buttonBackgroundOverlay
            anchors.fill: parent
            radius: parent.radius
            color: "black"
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 60 }
            }
        }
    }

    Component {
        id: buttonContent

        HRowLayout {
            id: contentLayout
            spacing: button.text && iconName ? 5 : 0
            Component.onCompleted: contentWidth = implicitWidth

            HIcon {
                svgName: loading ? "hourglass" : iconName
                dimension: iconDimension || contentLayout.height
                transform: iconTransform

                Layout.topMargin: verticalMargin
                Layout.bottomMargin: verticalMargin
                Layout.leftMargin: horizontalMargin
                Layout.rightMargin: horizontalMargin
            }

            HLabel {
                text: button.text
                font.pixelSize: fontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }

    Component {
        id: loadingOverlay
        HRowLayout {
            HIcon {
                svgName: "hourglass"
                Layout.preferredWidth: contentWidth || -1
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }

    contentItem: Loader {
        sourceComponent:
            loading && ! iconName ? loadingOverlay : buttonContent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onCanceled: button.canceled()
        onClicked: button.clicked()
        onDoubleClicked: button.doubleClicked()
        onEntered: {
            overlayOpacity = checked ? 0 : 0.15
            button.entered()
        }
        onExited: {
            overlayOpacity = 0
            button.exited()
        }
        onPressAndHold: button.pressAndHold()
        onPressed: {
            overlayOpacity += 0.15
            button.pressed()
        }
        onReleased: {
            if (checkable) { checked = ! checked }
            overlayOpacity = checked ? 0 : 0.15
            button.released()
        }
    }
}
