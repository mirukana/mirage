// SPDX-License-Identifier: LGPL-3.0-or-later

// The Utils class exposes various useful functions for QML that aren't
// normally provided by Qt.

#ifndef UTILS_H
#define UTILS_H

#include <QObject>
#include <QLocale>


class Utils : public QObject {

Q_OBJECT

public:
    Utils();

public slots:
    QString formattedBytes(qint64 bytes, int precision = 2);
    QString uuid();

private:
    QLocale m_locale;
};


#endif
