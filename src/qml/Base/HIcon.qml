import QtQuick 2.12
import QtGraphicalEffects 1.12

Image {
    id: icon
    cache: true
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    visible: Boolean(svgName)

    source: svgName ? `../../icons/${iconPack}/${svgName}.svg` : ""
    sourceSize.width: svgName ? dimension : 0
    sourceSize.height: svgName ? dimension : 0


    property string svgName: ""
    property int dimension: 20
    property color colorize: theme.icons.colorize
    property string iconPack: theme ? theme.icons.preferredPack : "thin"


    layer.enabled: ! Qt.colorEqual(colorize, "transparent")
    layer.effect: ColorOverlay {
        color: icon.colorize
        cached: icon.cache
    }
}
