// SPDX-License-Identifier: LGPL-3.0-or-later

// The Clipboard class exposes system clipboard management and retrieval
// to QML.

#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include <QGuiApplication>
#include <QClipboard>
#include <QObject>


class Clipboard : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QString selection READ selection WRITE setSelection
               NOTIFY selectionChanged)

    Q_PROPERTY(bool supportsSelection READ supportsSelection CONSTANT)

public:
    explicit Clipboard(QObject *parent = nullptr) : QObject(parent) {
        connect(this->clipboard, &QClipboard::dataChanged,
                this, &Clipboard::textChanged);

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
    void textChanged();
    void selectionChanged();

private:
    QClipboard *clipboard = QGuiApplication::clipboard();
};

#endif
