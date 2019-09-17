import QtQuick 2.12
import QtQuick.Controls 2.12

ProgressBar {
    id: bar

    property color backgroundColor: theme.controls.progressBar.background
    property color foregroundColor: theme.controls.progressBar.foreground

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: theme.controls.progressBar.height
        color: backgroundColor
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: theme.controls.progressBar.height

        Rectangle {
            width: bar.visualPosition * parent.width
            height: parent.height
            color: foregroundColor
        }
    }
}
