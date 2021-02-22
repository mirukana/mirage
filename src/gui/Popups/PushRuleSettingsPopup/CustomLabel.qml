// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HLabel {
    opacity: enabled ? 1 : theme.disabledElementsOpacity
    wrapMode: HLabel.Wrap
    Layout.fillWidth: true

    Behavior on opacity { HNumberAnimation {} }
}
