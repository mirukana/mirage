// SPDX-License-Identifier: LGPL-3.0-or-later

// Function implementations of the Utils class, see the utils.h file.

#include <QLocale>
#include <QUuid>

#include "utils.h"


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
