import QtQuick 2.12

QtObject {
    signal pressed(var event)
    signal held(var event)
    signal released(var event)

    property bool enabled: true
    property var sequences: ""  // shortcut string array of shortcut strings
}
