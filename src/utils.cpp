#include <QLocale>
#include <QUuid>

#include "utils.h"


Utils::Utils() {
    // Initialization
};


QString Utils::formattedBytes(qint64 bytes, int precision) {
    return m_locale.formattedDataSize(
        bytes, precision, QLocale::DataSizeTraditionalFormat
    );
};


QString Utils::uuid() {
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}
