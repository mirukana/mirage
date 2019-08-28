import QtQuick 2.12

HImage {
    property string svgName: ""
    property int dimension: 20


    visible: Boolean(svgName)
    colorize: theme.icons.colorize

    source:
        svgName ?
        ("../../icons/" + (theme ? theme.icons.preferredPack : "thin") +
         "/" + svgName + ".svg") :
        ""

    sourceSize.width: svgName ? dimension : 0
    sourceSize.height: svgName ? dimension : 0
}
