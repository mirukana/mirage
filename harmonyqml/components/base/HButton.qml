import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Button {
    property alias fontSize: buttonLabel.font.pixelSize
    property color backgroundColor: "lightgray"
    property alias overlayOpacity: buttonBackgroundOverlay.opacity
    property string iconName: ""
    property bool circle: false

    id: button
    display: Button.TextBesideIcon

    background: Rectangle {
        id: buttonBackground
        color: Qt.lighter(backgroundColor, checked ? 1.3 : 1.0)
        radius: circle ? height : 0

        Rectangle {
            id: buttonBackgroundOverlay
            anchors.fill: parent
            radius: parent.radius
            color: "black"
            opacity: 0
        }
    }

    contentItem: HRowLayout {
        spacing: button.text && iconName ? 5 : 0

        Component {
            id: buttonIcon
            Image {
                cache: true
                mipmap: true
                source: "../../icons/" + iconName + ".svg"
                fillMode: Image.PreserveAspectFit
                width: button.text ? 20 : 24
                height: width
            }
        }
        Loader {
            sourceComponent: iconName ? buttonIcon : undefined
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        HLabel {
            id: buttonLabel

            text: button.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth: button.width - buttonIcon.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true

        onEntered: overlayOpacity = checked ? 0 : 0.3
        onExited: overlayOpacity = 0
        onPressed: overlayOpacity += 0.3
        onReleased: {
            if (checkable) { checked = ! checked }
            overlayOpacity = checked ? 0 : 0.3
        }
    }
}
