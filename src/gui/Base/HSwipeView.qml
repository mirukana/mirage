// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

SwipeView {
    Component.onCompleted: if (! changed) {
        if (becomeKeyboardTabsTarget) shortcuts.tabsTarget = this
        setCurrentIndex(window.getState(this, "currentIndex", defaultIndex))
        saveEnabled = true
    }

    onCurrentIndexChanged: if (saveEnabled) window.saveState(this)


    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["currentIndex"]

    // Prevent onCurrentIndexChanged from running before Component.onCompleted
    property bool saveEnabled: false

    property bool becomeKeyboardTabsTarget: true
    property int defaultIndex: 0
    property bool changed: currentIndex !== defaultIndex


    function reset() { setCurrentIndex(defaultIndex) }
}
