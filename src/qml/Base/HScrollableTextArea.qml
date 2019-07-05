import QtQuick 2.7
import QtQuick.Controls 2.2

ScrollView {
    property alias backgroundColor: textAreaBackground.color
    property alias placeholderText: textArea.placeholderText
    property alias text: textArea.text
    property alias area: textArea

    default property alias textAreaData: textArea.data

    id: scrollView
    clip: true

    TextArea {
        id: textArea
        readOnly: ! visible
        selectByMouse: true

        wrapMode: TextEdit.Wrap
        font.family: HStyle.fontFamily.sans
        font.pixelSize: HStyle.fontSize.normal

        color: HStyle.colors.foreground
        background: Rectangle {
            id: textAreaBackground
            color: HStyle.controls.textArea.background
        }

        //Keys.forwardTo: [scrollView]
    }
}
