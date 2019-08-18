import QtQuick 2.12
import QtQuick.Controls 2.12

HFixedListView {
    interactive: true
    keyNavigationWraps: true

    // This is used to smooth scroll when currentIndex is changed
    highlightMoveDuration: theme.animationDuration * 4

    ScrollBar.vertical: ScrollBar {}
}
