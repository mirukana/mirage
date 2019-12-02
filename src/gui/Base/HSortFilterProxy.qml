// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import com.cutehacks.gel 1.0

Collection {
    caseSensitiveSort: false
    localeAwareSort: true
    Component.onCompleted: reSort()
}
