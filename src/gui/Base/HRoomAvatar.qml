// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

HAvatar {
    name: displayName[0] === "#" && displayName.length > 1 ?
          displayName.substring(1) :
          displayName


    property string displayName
}
