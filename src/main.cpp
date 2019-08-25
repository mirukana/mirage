#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QFileInfo>
#include <QUrl>


int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QApplication::setOrganizationName("harmonyqml");
    QApplication::setApplicationName("harmonyqml");
    QApplication::setApplicationDisplayName("HarmonyQML");
    QApplication::setApplicationVersion("0.1.0");

    QQmlEngine engine;
    QQmlContext *objectContext = new QQmlContext(engine.rootContext());

#ifdef QT_DEBUG
    objectContext->setContextProperty("debugMode", true);
#else
    objectContext->setContextProperty("debugMode", false);
#endif

    QFileInfo qrcPath(":/qml/Window.qml");

    QQmlComponent component(
        &engine,
        qrcPath.exists() ? "qrc:/qml/Window.qml" : "src/qml/Window.qml"
    );
    component.create(objectContext);

    return app.exec();
}
