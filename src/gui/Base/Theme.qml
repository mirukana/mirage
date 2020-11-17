// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

QtObject {
    id: root

    property Item target
    default property list<Class> classes

    readonly property var matchablePathRegex: utils.getClassPathRegex(target)
    readonly property var themeRules: window.themeRules
    readonly property var data: {
        const newData = {}

        for (const [path, section] of Object.entries(themeRules))
            if (matchablePathRegex.test(path))
                for (const [name, value] of Object.entries(section))
                    if (! name.startsWith("_"))
                        newData[name] = value

        return newData
    }
}
