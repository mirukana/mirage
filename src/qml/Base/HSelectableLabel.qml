import QtQuick 2.12
import QtQuick.Controls 2.12
import "../utils.js" as Utils

TextEdit {
    id: label
    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    color: theme.colors.text

    textFormat: Label.PlainText
    tabStopDistance: 4 * 4  // 4 spaces

    readOnly: true
    persistentSelection: true
    activeFocusOnPress: false
    focus: false

    onLinkActivated: Qt.openUrlExternally(link)


    // If index is a whole number, the label will get two \n before itself
    // in container.joinedSelection. If it's a decimal number, if gets one \n.
    property real index
    property HSelectableLabelContainer container
    property bool selectable: true


    function updateSelection() {
        if (! selectable && label.selectedText) {
            label.deselect()
            updateContainerSelectedTexts()
            return
        }

        if (! selectable) return

        if (! container.reversed &&
            container.selectionStart <= container.selectionEnd ||

            container.reversed &&
            container.selectionStart > container.selectionEnd)
        {
            var first    = container.selectionStart
            var firstPos = container.selectionStartPosition
            var last     = container.selectionEnd
            var lastPos  = container.selectionEndPosition
        } else {
            var first    = container.selectionEnd
            var firstPos = container.selectionEndPosition
            var last     = container.selectionStart
            var lastPos  = container.selectionStartPosition
        }

        if (first == index && last == index) {
            select(
                label.positionAt(firstPos.x, firstPos.y),
                label.positionAt(lastPos.x, lastPos.y),
            )

        } else if ((! container.reversed && first < index && index < last) ||
                   (container.reversed && first > index && index > last))
        {
            label.selectAll()

        } else if (first == index) {
            label.select(positionAt(firstPos.x, firstPos.y), length)

        } else if (last == index) {
            label.select(0, positionAt(lastPos.x, lastPos.y))

        } else {
            label.deselect()
        }

        updateContainerSelectedTexts()
    }

    function updateContainerSelectedTexts() {
        container.selectedTexts[index] = selectedText
        container.selectedTextsChanged()
    }

    function selectWordAt(position) {
        container.clearSelection()
        label.cursorPosition = positionAt(position.x, position.y)
        label.selectWord()
        updateContainerSelectedTexts()
    }

    function selectAllText() {
        container.clearSelection()
        label.selectAll()
        updateContainerSelectedTexts()
    }

    function selectAllTextPlus() {
        // Unimplemented by default
        container.clearSelection()
    }


    Connections {
        target: container
        onSelectionInfoChanged: updateSelection()
        onDeselectAll: deselect()
    }

    DropArea {
        anchors.fill: parent
        onPositionChanged: {
            if (! container.selecting) {
                container.clearSelection()
                container.selectionStart         = index
                container.selectionStartPosition = Qt.point(drag.x, drag.y)
                container.selecting              = true
            } else {
                container.selectionEnd         = index
                container.selectionEndPosition = Qt.point(drag.x, drag.y)
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            tapCount == 2 ? selectWordAt(eventPoint.position) :
            tapCount == 3 ? selectAllText() :
            tapCount == 4 ? selectAllTextPlus() :
            container.clearSelection()
        }
    }

    MouseArea {
        anchors.fill: label
        acceptedButtons: Qt.NoButton
        cursorShape: label.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
    }
}
