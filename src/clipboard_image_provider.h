// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

#ifndef CLIPBOARD_IMAGE_PROVIDER_H
#define CLIPBOARD_IMAGE_PROVIDER_H

#include <QImage>
#include <QQuickImageProvider>

#include "clipboard.h"


class ClipboardImageProvider : public QQuickImageProvider {
public:
    explicit ClipboardImageProvider(Clipboard *clipboard)
        : QQuickImageProvider(QQuickImageProvider::Image)
    {
        this->clipboard = clipboard;
    }

    QImage requestImage(
        const QString &id, QSize *size, const QSize &requestSize
    ) {
        Q_UNUSED(id);

        QImage *image = this->clipboard->qimage();

        if (size) *size = image->size();

        if (requestSize.width() > 0 && requestSize.height() > 0)
            return image->scaled(
                requestSize.width(), requestSize.height(), Qt::KeepAspectRatio
            );

       return *image;
    }

private:
    Clipboard *clipboard;
};

#endif
