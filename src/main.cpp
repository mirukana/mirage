#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QFileInfo>

#include "../submodules/RadialBarDemo/radialbar.h"

#include "utils.h"
#include "clipboard.h"


int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QApplication::setOrganizationName("harmonyqml");
    QApplication::setApplicationName("harmonyqml");
    QApplication::setApplicationDisplayName("HarmonyQML");
    QApplication::setApplicationVersion("0.2.3");
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);


    QQmlEngine engine;
    QQmlContext *objectContext = new QQmlContext(engine.rootContext());

#ifdef QT_DEBUG
    objectContext->setContextProperty("debugMode", true);
#else
    objectContext->setContextProperty("debugMode", false);
#endif

    objectContext->setContextProperty("CppUtils", new Utils());
    objectContext->setContextProperty("Clipboard", new Clipboard());

    qmlRegisterType<RadialBar>("RadialBar", 1, 0, "RadialBar");

    QFileInfo qrcPath(":src/qml/Window.qml");

    QQmlComponent component(
        &engine,
        qrcPath.exists() ? "qrc:/src/qml/Window.qml" : "src/qml/Window.qml"
    );
    component.create(objectContext);

    return app.exec();
}
