import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ColumnLayout {
    id: columnLayout
    spacing: 0

    property int totalSpacing:
        spacing * Math.max(0, (columnLayout.visibleChildren.length - 1))
}
