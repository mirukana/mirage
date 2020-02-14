// SPDX-License-Identifier: LGPL-3.0-or-later

// Function implementations of the Utils class, see the utils.h file.

#include <QColor>
#include <QLocale>
#include <QUuid>

#include "utils.h"
#include "../submodules/hsluv-c/src/hsluv.h"

using namespace std;


Utils::Utils() {
    // Initialization
}


QString Utils::formattedBytes(qint64 bytes, int precision) {
    return m_locale.formattedDataSize(
        bytes, precision, QLocale::DataSizeTraditionalFormat
    );
}


QString Utils::uuid() {
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}


QColor Utils::hsluv(qreal hue, qreal saturation, qreal luv, qreal alpha) {
    double red, green, blue;
    hsluv2rgb(hue, saturation, luv, &red, &green, &blue);

    return QColor::fromRgbF(
        qMax(0.0, qMin(1.0, red)),
        qMax(0.0, qMin(1.0, green)),
        qMax(0.0, qMin(1.0, blue)),
        qMax(0.0, qMin(1.0, alpha))
    );
}
