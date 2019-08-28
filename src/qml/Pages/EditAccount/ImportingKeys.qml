import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    HRowLayout {
        HLabel {
            text: qsTr("Importing decryption keys...")
            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.margins: currentSpacing
        }

        HLabel {
            text: qsTr("%1/%2")
                  .arg(Math.ceil(progressBar.value)).arg(progressBar.to)

            Layout.margins: currentSpacing
            Layout.leftMargin: 0
        }
    }

    ProgressBar {
        id: progressBar
        from: 0
        value: accountInfo.importing_key
        to: accountInfo.total_keys_to_import

        Behavior on value { HNumberAnimation { factor: 5 } }

        Layout.fillWidth: true
    }
}
