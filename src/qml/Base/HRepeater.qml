import QtQuick.Controls 2.12
import QtQuick 2.12


Repeater {
    id: repeater

    readonly property int childrenImplicitWidth: {
        let total = 0

        for (let i = 0;  i < repeater.count; i++) {
            total += repeater.itemAt(i).implicitWidth
        }

        return total
    }
}
