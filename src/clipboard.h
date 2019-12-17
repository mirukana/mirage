// The Clipboard class exposes system clipboard management and retrieval
// to QML.

#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include <QGuiApplication>
#include <QObject>


class Clipboard : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QString selection READ selection WRITE setSelection
               NOTIFY selectionChanged)

    Q_PROPERTY(bool supportsSelection READ supportsSelection CONSTANT)

public:
    explicit Clipboard(QObject *parent = 0);

    // Normal primary clipboard
    QString text() const;
    void setText(const QString &text);

    // X11 select-middle-click-paste clipboard
    QString selection() const;
    void setSelection(const QString &text);

    bool supportsSelection() const;

signals:
    void textChanged();
    void selectionChanged();

private:
    QClipboard *m_clipboard = QGuiApplication::clipboard();
};


#endif
