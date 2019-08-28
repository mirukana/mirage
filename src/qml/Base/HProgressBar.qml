import QtQuick 2.12
import QtQuick.Controls 2.12

ProgressBar {
    id: bar

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: theme.controls.progressBar.height
        color: theme.controls.progressBar.background
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: theme.controls.progressBar.height

        Rectangle {
            width: bar.visualPosition * parent.width
            height: parent.height
            color: theme.controls.progressBar.foreground
        }
    }
}
