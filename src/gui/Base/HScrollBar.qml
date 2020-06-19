// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

ScrollBar {
    minimumSize: (Math.min(height / 1.5, 48) * theme.uiScale) / height
}
