// SPDX-License-Identifier: LGPL-3.0-or-later

#ifndef CLIPBOARD_IMAGE_PROVIDER_H
#define CLIPBOARD_IMAGE_PROVIDER_H

#include <QClipboard>
#include <QImage>
#include <QQuickImageProvider>


class ClipboardImageProvider : public QQuickImageProvider {

public:
    explicit ClipboardImageProvider()
        : QQuickImageProvider(QQuickImageProvider::Image) {}

    QImage requestImage(
        const QString &id, QSize *size, const QSize &requestSize
    ) {
        Q_UNUSED(id);

        QImage image = this->clipboard->image();

        if (size) *size = image.size();

        if (requestSize.width() > 0 && requestSize.height() > 0)
            image = image.scaled(
                requestSize.width(), requestSize.height(), Qt::KeepAspectRatio
            );

       return image;
    }

private:
    QClipboard *clipboard = QGuiApplication::clipboard();
};

#endif
