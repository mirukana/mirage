// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

pragma Singleton
import QtQuick 2.12

QtObject {

    property bool startInTray: false
    property string loadQml: ""

    readonly property string help: `Usage: ${Qt.application.name} [options]

    Options:
        -t, --start-in-tray  Start in the system tray, without a visible window
        -l, --load-qml PATH  Override the file to be loaded as src/gui/UI.qml
        -V, --version        Show the application's version and exit
        -h, --help           Show this help and exit

    Environment variables:
        MIRAGE_CONFIG_DIR  Override the default configuration folder
        MIRAGE_DATA_DIR    Override the default application data folder
        MIRAGE_CACHE_DIR   Override the default cache and downloads folder
    `

    readonly property bool ready: {
        const passedArguments = Qt.application.arguments.slice(1)

        while (passedArguments.length) {
            switch (passedArguments.shift()) {
                case "-h":
                case "--help":
                    print("\n\n" + help.replace(/^ {4}/gm, ""))
                    Qt.quit()
                    break

                case "-v":
                case "--version":
                    print(Qt.application.version)
                    Qt.quit()
                    break

                case "-t":
                case "--start-in-tray":
                    startInTray = true
                    break

                case "-l":
                case "--load-qml":
                    loadQml = passedArguments.shift()
                    break
            }
        }

        return true
    }
}
