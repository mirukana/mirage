// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import "../ShortcutBundles"

SwipeView {
    id: swipeView

    Component.onCompleted: if (! changed) {
        setCurrentIndex(window.getState(this, "currentIndex", defaultIndex))
        saveEnabled = true
    }

    onCurrentIndexChanged: {
        if (saveEnabled) window.saveState(this)

        if (currentIndex < previousIndex) lastMove = HSwipeView.Move.ToPrevious
        if (currentIndex > previousIndex) lastMove = HSwipeView.Move.ToNext

        previousIndex = currentIndex
    }


    enum Move { ToPrevious, ToNext }

    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["currentIndex"]

    // Prevent onCurrentIndexChanged from running before Component.onCompleted
    property bool saveEnabled: false

    property int previousIndex: 0
    property int defaultIndex: 0
    property int lastMove: HSwipeView.Move.ToNext
    property bool changed: currentIndex !== defaultIndex


    function reset() { setCurrentIndex(defaultIndex) }

    function incrementWrapIndex() {
        currentIndex === count - 1 ?
        setCurrentIndex(0) :
        incrementCurrentIndex()
    }

    function decrementWrapIndex() {
        currentIndex === 0 ?
        setCurrentIndex(count - 1) :
        decrementCurrentIndex()
    }


    TabShortcuts {
        container: swipeView
    }
}
