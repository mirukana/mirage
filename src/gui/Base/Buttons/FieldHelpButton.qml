// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HButton {
    property string helpText

    icon.name: "field-help"
    iconItem.small: true
    toolTip.text: helpText

    onClicked: toolTip.instantToggle()
    onActiveFocusChanged: if (! activeFocus && toolTip.visible) toolTip.hide()

    Layout.fillHeight: true
}
