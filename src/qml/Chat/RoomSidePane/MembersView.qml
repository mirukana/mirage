// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import SortFilterProxyModel 0.2
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    HListView {
        id: memberList
        bottomMargin: currentSpacing

        model: HListModel {
            sourceModel: chatPage.roomInfo.members

            proxyRoles: ExpressionRole {
                name: "displayName"
                expression: users.find(userId).displayName || userId
            }

            sorters: StringSorter {
                roleName: "displayName"
            }

            filters: ExpressionFilter {
                function filterIt(filter, text) {
                    return Utils.filterMatches(filter, text)
                }
                expression: filterIt(filterField.text, displayName)
            }
        }

        delegate: MemberDelegate {}

        Layout.fillWidth: true
        Layout.fillHeight: true

    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter members")
        backgroundColor: theme.sidePane.filterRooms.background

        Layout.fillWidth: true
        Layout.preferredHeight: theme.baseElementsHeight
    }
}
