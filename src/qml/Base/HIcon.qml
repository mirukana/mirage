// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7

HImage {
    property var svgName: null
    property int dimension: 20

    source: "../../icons/" + (svgName || "none") + ".svg"
    sourceSize.width: svgName ? dimension : 0
    sourceSize.height: svgName ? dimension : 0
}
