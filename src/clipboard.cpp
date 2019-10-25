#include <QClipboard>
#include "clipboard.h"


Clipboard::Clipboard(QObject *parent)
    : QObject(parent) {

    connect(m_clipboard, &QClipboard::dataChanged,
            this, &Clipboard::textChanged);

    connect(m_clipboard, &QClipboard::selectionChanged,
            this, &Clipboard::selectionChanged);
}


QString Clipboard::text() const {
    return m_clipboard->text(QClipboard::Clipboard);
}

void Clipboard::setText(const QString &text) {
    m_clipboard->setText(text, QClipboard::Clipboard);
}


QString Clipboard::selection() const {
    return m_clipboard->text(QClipboard::Selection);
}

void Clipboard::setSelection(const QString &text) {
    if (m_clipboard->supportsSelection()) {
        m_clipboard->setText(text, QClipboard::Selection);
    }
}


bool Clipboard::supportsSelection() const {
    return m_clipboard->supportsSelection();
}
