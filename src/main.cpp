#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QFileInfo>

#include "utils.h"


int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QApplication::setOrganizationName("harmonyqml");
    QApplication::setApplicationName("harmonyqml");
    QApplication::setApplicationDisplayName("HarmonyQML");
    QApplication::setApplicationVersion("0.2.3");

    QQmlEngine engine;
    QQmlContext *objectContext = new QQmlContext(engine.rootContext());

#ifdef QT_DEBUG
    objectContext->setContextProperty("debugMode", true);
#else
    objectContext->setContextProperty("debugMode", false);
#endif

    objectContext->setContextProperty("CppUtils", new Utils());

    QFileInfo qrcPath(":src/qml/Window.qml");

    QQmlComponent component(
        &engine,
        qrcPath.exists() ? "qrc:/src/qml/Window.qml" : "src/qml/Window.qml"
    );
    component.create(objectContext);

    return app.exec();
}
