// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HListView {
    id: accountList
    clip: true

    model: accounts
    delegate: AccountDelegate {}
}
