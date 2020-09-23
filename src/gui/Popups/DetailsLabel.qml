// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HLabel {
    wrapMode: HLabel.Wrap
    visible: Boolean(text)

    Layout.fillWidth: true
}
