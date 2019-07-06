import QtQuick.Controls 2.2

Label {
    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    textFormat: Label.PlainText

    color: theme.colors.foreground
    style: Label.Outline
    styleColor: theme.colors.textBorder
}
