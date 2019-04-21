import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Button {
    property string iconName: ""

    id: button
    display: Button.TextBesideIcon
    icon.source: "../../icons/" + iconName + ".svg"
}
