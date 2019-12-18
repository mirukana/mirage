import QtQuick 2.12

Loader {
    id: loader
    asynchronous: true
    visible: status === Loader.Ready
}
