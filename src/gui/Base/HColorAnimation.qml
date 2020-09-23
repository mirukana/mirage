// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

ColorAnimation {
    property real factor: 1.0


    duration: theme.animationDuration * factor
}
