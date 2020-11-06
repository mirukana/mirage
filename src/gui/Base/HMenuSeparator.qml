// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

MenuSeparator {
    id: separator
    padding: 0
    contentItem: Item {
        implicitHeight: separator.visible ? theme.spacing : 0
    }
}
