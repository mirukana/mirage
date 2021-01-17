// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HButton {
    property bool show: true

    visible: Layout.preferredWidth > 0

    Layout.preferredWidth: show ? implicitWidth : 0
    Layout.fillHeight: true

    Behavior on Layout.preferredWidth { HNumberAnimation {} }
}
