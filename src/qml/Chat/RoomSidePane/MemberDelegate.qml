// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HHighlightRectangle {
    id: memberDelegate
    width: memberList.width
    height: childrenRect.height

    property var memberInfo: users.find(model.userId)

    Row {
        width: parent.width - leftPadding * 2
        padding: roomSidePane.currentSpacing / 2
        leftPadding: roomSidePane.currentSpacing
        rightPadding: 0

        HRowLayout {
            width: parent.width
            spacing: roomSidePane.currentSpacing

            HUserAvatar {
                id: avatar
                userId: model.userId
            }

            HColumnLayout {
                Layout.fillWidth: true

                HLabel {
                    id: memberName
                    text: memberInfo.displayName || model.userId
                    elide: Text.ElideRight
                    verticalAlignment: Qt.AlignVCenter

                    Layout.fillWidth: true
                }
            }
        }
    }
}
