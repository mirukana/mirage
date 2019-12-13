import QtQuick.Controls 2.12

SwipeView {
    currentIndex: window.getState(this, "currentIndex", defaultIndex)
    onCurrentIndexChanged: window.saveState(this)


    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["currentIndex"]

    property int defaultIndex: 0
    property bool changed: currentIndex !== defaultIndex


    function reset() { setCurrentIndex(defaultIndex) }
}
