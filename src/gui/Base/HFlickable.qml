import QtQuick 2.12
import QtQuick.Controls 2.12

Flickable {
    interactive: contentWidth > width || contentHeight > height
    ScrollBar.vertical: ScrollBar {}
}
