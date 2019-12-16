
import QtQuick 2.12
import QtQuick.Controls 2.12

ScrollView {
    id: scrollView
    opacity: enabled ? 1 : theme.disabledElementsOpacity
    clip: true
    ScrollBar.vertical.visible: contentHeight > height

    // Set it only on component creation to avoid binding loops
    Component.onCompleted: if (! text) {
        text                    = window.getState(this, "text", "")
        textArea.cursorPosition = text.length
    }

    onTextChanged: window.saveState(this)


    default property alias textAreaData: textArea.data

    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["text"]

    property alias backgroundColor: textAreaBackground.color
    property alias placeholderText: textArea.placeholderText
    property alias placeholderTextColor: textArea.placeholderTextColor
    property alias area: textArea
    property alias text: textArea.text

    property var focusItemOnTab: null
    property var disabledText: null
    property string defaultText: ""
    readonly property bool changed: text !== defaultText


    function reset() { area.clear(); text = defaultText }


    Behavior on opacity { HNumberAnimation {} }

    TextArea {
        id: textArea
        text: defaultText
        enabled: parent.enabled
        leftPadding: theme.spacing
        rightPadding: leftPadding
        topPadding: theme.spacing / 1.5
        bottomPadding: topPadding

        readOnly: ! visible
        selectByMouse: true

        wrapMode: TextEdit.Wrap
        font.family: theme.fontFamily.sans
        font.pixelSize: theme.fontSize.normal
        font.pointSize: -1

        placeholderTextColor: theme.controls.textArea.placeholderText
        color: theme.controls.textArea.text

        background: Rectangle {
            id: textAreaBackground
            color: theme.controls.textArea.background
        }

        Keys.onPressed: if (
            event.modifiers & Qt.AltModifier ||
            event.modifiers & Qt.MetaModifier
        ) event.accepted = true

        KeyNavigation.priority: KeyNavigation.BeforeItem
        KeyNavigation.tab: focusItemOnTab


        Binding on color {
            value: "transparent"
            when: disabledText !== null && ! textArea.enabled
        }

        Binding on placeholderTextColor {
            value: "transparent"
            when: disabledText !== null && ! textArea.enabled
        }

        Behavior on color { HColorAnimation {} }
        Behavior on placeholderTextColor { HColorAnimation {} }

        HLabel {
            anchors.fill: parent
            visible: opacity > 0
            opacity: disabledText !== null && parent.enabled ? 0 : 1
            text: disabledText || ""

            leftPadding: parent.leftPadding
            rightPadding: parent.rightPadding
            topPadding: parent.topPadding
            bottomPadding: parent.bottomPadding

            wrapMode: parent.wrapMode
            font.family: parent.font.family
            font.pixelSize: parent.font.pixelSize

            Behavior on opacity { HNumberAnimation {} }
        }
    }
}
