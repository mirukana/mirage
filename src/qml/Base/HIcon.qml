import QtQuick 2.12

HImage {
    visible: Boolean(svgName)

    property string svgName: ""
    property int dimension: 20

    source:
        svgName ?
        ("../../icons/" + theme.preferredIconPack + "/" + svgName + ".svg") :
        ""

    sourceSize.width: svgName ? dimension : 0
    sourceSize.height: svgName ? dimension : 0
}
