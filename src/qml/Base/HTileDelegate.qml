import QtQuick 2.12
import QtQuick.Layouts 1.12

HTile {
    id: tile
    onActivated: view.currentIndex = model.index
    onLeftClicked: {
        view.highlightRangeMode    = ListView.NoHighlightRange
        view.highlightMoveDuration = 0
        activated()
        view.highlightRangeMode    = ListView.ApplyRange
        view.highlightMoveDuration = theme.animationDuration
    }


    signal activated()

    property HListView view: ListView.view
    property bool shouldBeCurrent: false

    readonly property QtObject delegateModel: model

    readonly property alias setCurrentTimer: setCurrentTimer


    Timer {
        id: setCurrentTimer
        interval: 100
        repeat: true
        running: true
        // Component.onCompleted won't work for this
        onTriggered: if (shouldBeCurrent) view.currentIndex = model.index
    }
}
