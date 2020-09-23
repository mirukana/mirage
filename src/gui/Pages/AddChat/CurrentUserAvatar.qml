// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HUserAvatar {
    property QtObject account


    clientUserId: userId
    displayName: account ? account.display_name : ""
    mxc: account ? account.avatar_url : ""

    Layout.alignment: Qt.AlignCenter
    Layout.preferredWidth: 128
    Layout.preferredHeight: Layout.preferredWidth
}
