// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

// The Utils class exposes various useful functions for QML that aren't
// provided by the `Qt` object.

#ifndef UTILS_H
#define UTILS_H

#include <QColor>
#include <QLocale>
#include <QObject>
#include <QUuid>

#ifdef Q_OS_LINUX
    #ifndef NO_X11
    #define USE_LINUX_AUTOAWAY
    #include <X11/extensions/scrnsaver.h>
    #endif
#endif

#include "../submodules/hsluv-c/src/hsluv.h"


class Utils : public QObject {
    Q_OBJECT

public:
    Utils() {};

public slots:
    QString formattedBytes(qint64 bytes, int precision = 2) {
        return this->appLocale.formattedDataSize(
            bytes, precision, QLocale::DataSizeTraditionalFormat
        );
    }

    QString uuid() const {
        return QUuid::createUuid().toString(QUuid::WithoutBraces);
    }

    QColor hsluv(qreal hue, qreal sat, qreal luv, qreal alpha = 1.0) const {
        double red, green, blue;

        hsluv2rgb(
            hue,
            qMax(0.0, qMin(100.0, sat)),
            qMax(0.0, qMin(100.0, luv)),
            &red, &green, &blue
        );

        return QColor::fromRgbF(
            qMax(0.0, qMin(1.0, red)),
            qMax(0.0, qMin(1.0, green)),
            qMax(0.0, qMin(1.0, blue)),
            qMax(0.0, qMin(1.0, alpha))
        );
    }

    int idleMilliseconds() const {
        #ifdef Q_OS_DARWIN
        return -1;

        #elif defined(USE_LINUX_AUTOAWAY)
        if (! this->waylandDisplay.isEmpty()) return -1;

        Display *display = XOpenDisplay(NULL);
        if (! display) return -1;

        int supportedVersion = 0, error = 0;
        if (! XScreenSaverQueryExtension(display, &supportedVersion, &error))
            return -1;

        XScreenSaverInfo *info = XScreenSaverAllocInfo();
        XScreenSaverQueryInfo(display, DefaultRootWindow(display), info);
        XFree(info);
        const int idle = info->idle;

        XCloseDisplay(display);
        return idle;

        #elif defined(Q_OS_WINDOWS)
        return -1;

        #else
        return -1;

        #endif
    }

private:
    QLocale appLocale;
    QString waylandDisplay = qEnvironmentVariable("WAYLAND_DISPLAY");
};


#endif
