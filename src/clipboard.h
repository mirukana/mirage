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

    QString text() const;
    void setText(const QString &text);

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
