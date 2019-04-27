import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../../base" as Base

Base.HImage {
    id: loginPage
    fillMode: Image.PreserveAspectCrop
    source: "../../../images/login_background.jpg"

    Loader {
        anchors.centerIn: parent
        Component.onCompleted: setSource(
            "SignInBox.qml", { "container": loginPage }
        )
    }
}
