// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

ScrollView {
    id: scrollView

    ScrollBar.vertical: HScrollBar {
        parent: scrollView
        x: scrollView.mirrored ? 0 : scrollView.width - width
        y: scrollView.topPadding
        height: scrollView.availableHeight
    }
}
