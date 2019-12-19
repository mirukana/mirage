// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

HNoticePage {
    text: model.date.toLocaleDateString()
    color: theme.chat.daybreak.text
    backgroundColor: theme.chat.daybreak.background
    radius: theme.chat.daybreak.radius
}
