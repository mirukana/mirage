// SPDX-License-Identifier: LGPL-3.0-or-later

// The Utils class exposes various useful functions for QML that aren't
// provided by the `Qt` object.

#ifndef UTILS_H
#define UTILS_H

#include <QColor>
#include <QLocale>
#include <QObject>


class Utils : public QObject {

Q_OBJECT

public:
    Utils();

public slots:
    QString formattedBytes(qint64 bytes, int precision = 2);
    QString uuid();
    QColor hsluv(qreal hue, qreal saturation, qreal luv, qreal alpha = 1.0);

private:
    QLocale m_locale;
};


#endif
