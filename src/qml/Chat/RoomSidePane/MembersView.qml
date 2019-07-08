// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Layouts 1.3
import SortFilterProxyModel 0.2
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    property bool collapsed: false
    property int normalSpacing: collapsed ? 0 : 8

    Behavior on normalSpacing { HNumberAnimation {} }

    HListView {
        id: memberList

        spacing: normalSpacing
        topMargin: normalSpacing
        bottomMargin: normalSpacing
        Layout.leftMargin: normalSpacing
        Layout.rightMargin: normalSpacing

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
        Layout.preferredHeight: theme.bottomElementsHeight
    }
}
