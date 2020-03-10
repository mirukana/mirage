// SPDX-License-Identifier: LGPL-3.0-or-later

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
    QApplication::setOrganizationName("mirage");
    QApplication::setApplicationName("mirage");
    QApplication::setApplicationDisplayName("Mirage");
    QApplication::setApplicationVersion("0.4.0");
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

    // Register our custom non-visual QObject singletons,
    // that will be importable anywhere in QML. Example:
    //     import Clipboard 0.1
    //     ...
    //     Component.onCompleted: print(Clipboard.text)
    qmlRegisterSingletonType<Clipboard>(
        "Clipboard", 0, 1, "Clipboard",
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return new Clipboard();
        }
    );

    qmlRegisterSingletonType<Utils>(
        "CppUtils", 0, 1, "CppUtils",
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return new Utils();
        }
    );

    // Register our custom visual items that will be importable from QML, e.g.
    //     import RadialBar 1.0
    //     ...
    //     RadialBar { ... }
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
