import QtQuick.Controls 2.2

Label {
    font.family: HStyle.fontFamily.sans
    font.pixelSize: HStyle.fontSize.normal
    textFormat: Label.PlainText

    color: HStyle.colors.foreground
    style: Label.Outline
    styleColor: HStyle.colors.textBorder
}
