import QtQuick.Controls 2.12
import QtQuick 2.12


Repeater {
    id: repeater

    readonly property int childrenImplicitWidth: {
        let total = 0

        for (let i = 0;  i < repeater.count; i++) {
            let item = repeater.itemAt(i)
            if (item && item.implicitWidth) total += item.implicitWidth
        }

        return total
    }

    readonly property int childrenWidth: {
        let total = 0

        for (let i = 0;  i < repeater.count; i++) {
            let item = repeater.itemAt(i)
            if (item && item.width) total += item.width
        }

        return total
    }
}
