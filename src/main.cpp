// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

// This file creates the application, registers custom objects for QML
// and launches Window.qml (the root component).

#include <QDataStream>  // must be first include to avoid clipboard.h errors
#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QFileInfo>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QLockFile>
#include <signal.h>

#ifdef Q_OS_UNIX
#include <unistd.h>
#endif

#include "utils.h"
#include "clipboard.h"
#include "clipboard_image_provider.h"


QLockFile *lockFile = nullptr;


void loggingHandler(
    QtMsgType type,
    const QMessageLogContext &context,
    const QString &msg
) {
    // Override default QML logger to provide colorful logging with times

    Q_UNUSED(context)

    // Hide dumb warnings about thing we can't fix without breaking
    // compatibilty with Qt < 5.14/5.15
    if (msg.contains("QML Binding: Not restoring previous value because"))
        return;

    if (msg.contains("QML Connections: Implicitly defined onFoo properties"))
        return;

    // Hide layout-related spam introduced in Qt 5.14
    if (msg.contains("Qt Quick Layouts: Detected recursive rearrange."))
        return;

    const char* level =
        type == QtDebugMsg ?    "~" :
        type == QtInfoMsg ?     "i" :
        type == QtWarningMsg ?  "!" :
        type == QtCriticalMsg ? "X" :
        type == QtFatalMsg ?    "F" :
        "?";

    QString boldColor = "", color = "", clearFormatting = "";

#ifdef Q_OS_UNIX
    // Don't output escape codes if stderr is piped or redirected to a file
    if (isatty(fileno(stderr))) {
        const QString ansiColor =
            type == QtInfoMsg ?     "2" :  // green
            type == QtWarningMsg ?  "3" :  // yellow
            type == QtCriticalMsg ? "1" :  // red
            type == QtFatalMsg ?    "5" :  // purple
            "4";                           // blue

        boldColor       = "\e[1;3" + ansiColor + "m";
        color           = "\e[3" + ansiColor + "m";
        clearFormatting = "\e[0m";
    }
#endif

    fprintf(
        stderr,
        "%s%s%s %s%s |%s %s\n",
        boldColor.toUtf8().constData(),
        level,
        clearFormatting.toUtf8().constData(),
        color.toUtf8().constData(),
        QDateTime::currentDateTime().toString("hh:mm:ss").toUtf8().constData(),
        clearFormatting.toUtf8().constData(),
        msg.toUtf8().constData()
    );
}


void onExitSignal(int signum) {
    QApplication::exit(128 + signum);
}


bool setLockFile(QString configPath) {

    QDir settingsFolder(configPath);

    if (! settingsFolder.mkpath(".")) {
        qFatal("Could not create config directory");
        exit(EXIT_FAILURE);
    }

    lockFile = new QLockFile(settingsFolder.absoluteFilePath(".lock"));
    lockFile->tryLock(0);

    switch (lockFile->error()) {
        case QLockFile::NoError:
            return true;
        case QLockFile::LockFailedError: {
            qWarning("Opening already running instance");
            QFile showFile(settingsFolder.absoluteFilePath(".show"));
            showFile.open(QIODevice::WriteOnly);
            showFile.close();
            return false;
        }
        default:
            qFatal("Cannot create lock file: no permission or unknown error");
            exit(EXIT_FAILURE);
    }
}


int main(int argc, char *argv[]) {
    qInstallMessageHandler(loggingHandler);

    // Define some basic info about the app before creating the QApplication
    QApplication::setOrganizationName("mirage");
    QApplication::setApplicationName("mirage");
    QApplication::setApplicationDisplayName("Mirage");
    QApplication::setApplicationVersion("0.6.4");
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QString customConfigDir(qEnvironmentVariable("MIRAGE_CONFIG_DIR"));
    QString settingsFolder(
        customConfigDir.isEmpty() ?
        QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + "/" + QApplication::applicationName() :
        customConfigDir
    );

    if (! setLockFile(settingsFolder)) return EXIT_SUCCESS;
    QApplication app(argc, argv);

    // Register handlers for quit signals, e.g. SIGINT/Ctrl-C in unix terminals
    signal(SIGINT, onExitSignal);
    #ifdef Q_OS_UNIX
    signal(SIGHUP, onExitSignal);
    #endif


    // Force the default universal QML style, notably prevents
    // KDE from hijacking base controls and messing up everything
    QQuickStyle::setStyle("Fusion");
    QQuickStyle::setFallbackStyle("Default");

    // Register default theme fonts. Take the files  from the
    // Qt resource system if possible (resources stored in the app executable),
    // else the local file system.
    // The dev qmake flag disables the resource system for faster builds.
    QFileInfo qrcPath(":src/gui/Window.qml");
    QString src = qrcPath.exists() ? ":/src" : "src";

    QList<QString> fontFamilies;
    fontFamilies << "roboto" << "hack";

    QList<QString> fontVariants;
    fontVariants << "regular" << "italic" << "bold" << "bold-italic";

    foreach (QString family, fontFamilies) {
        foreach (QString var, fontVariants) {
            QFontDatabase::addApplicationFont(
                src + "/fonts/" + family + "/" + var + ".ttf"
            );
        }
    }

    // Create the QML engine and get the root context.
    // We will add it some properties that will be available globally in QML.
    QQmlEngine engine;
    QQmlContext *objectContext = new QQmlContext(engine.rootContext());

    // To able to use Qt.quit() from QML side
    QObject::connect(
        &engine, &QQmlEngine::quit, &app, &QApplication::quit, Qt::QueuedConnection
    );

    // Set the debugMode properties depending of if we're running in debug mode
    // or not (`qmake CONFIG+=dev ...`, default in autoreload.py)
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
            Q_UNUSED(scriptEngine)

            Clipboard *clipboard = new Clipboard();

            // Register out custom image providers.
            // QML will be able to request an image from them by setting an
            // `Image`'s `source` to `image://<providerId>/<id>`
            engine->addImageProvider(
                "clipboard", new ClipboardImageProvider(clipboard)
            );

            return clipboard;
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

    // Create the QML root component by loading its file from the Qt Resource
    // System or local file system if not possible.
    QQmlComponent component(
        &engine,
        qrcPath.exists() ? "qrc:/src/gui/Window.qml" : "src/gui/Window.qml"
    );

    if (component.isError()) {
        for (QQmlError e : component.errors()) {
            qCritical(
                "%s:%d:%d: %s",
                e.url().toString().toStdString().c_str(),
                e.line(),
                e.column(),
                e.description().toStdString().c_str()
            );
        }
        qFatal("One or more errors have occurred, exiting");
        app.exit(EXIT_FAILURE);
    }

    component.create(objectContext)->setProperty("settingsFolder", settingsFolder);

    // Finally, execute the app. Return its exit code after clearing the lock.
    int exit_code = app.exec();
    delete lockFile;
    return exit_code;
}
