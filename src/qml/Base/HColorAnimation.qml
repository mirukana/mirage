// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

ColorAnimation {
    property real factor: 1.0
    duration: theme.animationDuration * factor
}
