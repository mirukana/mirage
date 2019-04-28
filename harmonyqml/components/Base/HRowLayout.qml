import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

RowLayout {
    id: rowLayout
    spacing: 0

    property int totalSpacing:
        spacing * Math.max(0, (rowLayout.visibleChildren.length - 1))
}
