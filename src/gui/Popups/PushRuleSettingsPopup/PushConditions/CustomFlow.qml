// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

HFlow {
    spacing: theme.spacing / 2

    // transitions break CustomLabel opacity for some reason
    populate: null
    add: null
    move: null
}
