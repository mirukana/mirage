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
