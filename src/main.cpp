// This file creates the application, registers custom objects for QML
// and launches Window.qml (the root component).

#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QFileInfo>

#include "../submodules/RadialBarDemo/radialbar.h"

#include "utils.h"
#include "clipboard.h"


int main(int argc, char *argv[]) {
    // Define some basic info about the app before creating the QApplication
    QApplication::setOrganizationName("harmonyqml");
    QApplication::setApplicationName("harmonyqml");
    QApplication::setApplicationDisplayName("HarmonyQML");
    QApplication::setApplicationVersion("0.2.3");
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);

    // Create the QML engine and get the root context.
    // We will add it some properties that will be available globally in QML.
    QQmlEngine engine;
    QQmlContext *objectContext = new QQmlContext(engine.rootContext());

    // Set the debugMode properties depending of if we're running in debug mode
    // or not (`qmake CONFIG+=dev ...`, default in live-reload.sh)
#ifdef QT_DEBUG
    objectContext->setContextProperty("debugMode", true);
#else
    objectContext->setContextProperty("debugMode", false);
#endif

    // Add our custom non-visual `QObject `s as properties.
    // Their attributes and methods will be accessing like normal QML objects.
    objectContext->setContextProperty("CppUtils", new Utils());
    objectContext->setContextProperty("Clipboard", new Clipboard());

    // Register our custom visual items that will be importable from QML,
    // e.g. `import RadialBar 1.0`
    qmlRegisterType<RadialBar>("RadialBar", 1, 0, "RadialBar");

    // Create the QML root component by loading its file from the Qt Resource
    // System (qrc:/, resources stored in the app's executable) if possible,
    // else fall back to the filesystem.
    // The dev qmake flag disables the resource system for faster builds.
    QFileInfo qrcPath(":src/gui/Window.qml");
    QQmlComponent component(
        &engine,
        qrcPath.exists() ? "qrc:/src/gui/Window.qml" : "src/gui/Window.qml"
    );
    component.create(objectContext);

    // Finally, execute the app. Return its system exit code when it exits.
    return app.exec();
}
