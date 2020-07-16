// SPDX-License-Identifier: LGPL-3.0-or-later

// The Clipboard class exposes system clipboard management and retrieval
// to QML.

#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include <QBuffer>
#include <QByteArray>
#include <QClipboard>
#include <QGuiApplication>
#include <QIODevice>
#include <QImage>
#include <QMimeData>
#include <QObject>


class Clipboard : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QByteArray image READ image WRITE setImage NOTIFY imageChanged)
    Q_PROPERTY(bool hasImage READ hasImage NOTIFY hasImageChanged)

    Q_PROPERTY(QString selection READ selection WRITE setSelection
               NOTIFY selectionChanged)

    Q_PROPERTY(bool supportsSelection READ supportsSelection CONSTANT)

public:
    explicit Clipboard(QObject *parent = nullptr) : QObject(parent) {
        connect(this->clipboard, &QClipboard::dataChanged,
                this, &Clipboard::mainClipboardChanged);

        connect(this->clipboard, &QClipboard::selectionChanged,
                this, &Clipboard::selectionChanged);
    }

    // Normal primary clipboard

    QString text() const {
        return this->clipboard->text(QClipboard::Clipboard);
    }

    void setText(const QString &text) const {
        this->clipboard->setText(text, QClipboard::Clipboard);
    }

    QByteArray image() const {
        QByteArray byteArray;
        QBuffer buffer(&byteArray);
        buffer.open(QIODevice::WriteOnly);
        this->clipboard->image(QClipboard::Clipboard).save(&buffer, "PNG");
        buffer.close();
        return byteArray;
    }

    void setImage(const QByteArray &image) const {  // TODO
        Q_UNUSED(image)
    }

    bool hasImage() const {
        return this->clipboard->mimeData()->hasImage();
    }

    // X11 select-middle-click-paste clipboard

    QString selection() const {
        return this->clipboard->text(QClipboard::Selection);
    }

    void setSelection(const QString &text) const {
        if (this->clipboard->supportsSelection()) {
            this->clipboard->setText(text, QClipboard::Selection);
        }
    }

    // Info

    bool supportsSelection() const {
        return this->clipboard->supportsSelection();
    }

signals:
    void contentChanged();
    void textChanged();
    void imageChanged();
    void hasImageChanged();
    void selectionChanged();

private:
    QClipboard *clipboard = QGuiApplication::clipboard();

    void mainClipboardChanged() {
        contentChanged();
        this->hasImage() ? this->imageChanged() : this->textChanged();
        this->hasImageChanged();
    };
};

#endif
