#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class QSettings;

class AppSettings : public QObject
{
    Q_OBJECT
public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings();

    Q_INVOKABLE QVariantList favourites() const;
    Q_INVOKABLE bool isFavourite(const QString &id) const;
    Q_INVOKABLE void addFavourite(const QVariantMap &station);
    Q_INVOKABLE void removeFavourite(const QString &id);

    Q_INVOKABLE QVariantList recents() const;
    Q_INVOKABLE void addRecent(const QVariantMap &journey);
    Q_INVOKABLE void removeRecent(int index);
    Q_INVOKABLE void clearRecents();

private:
    QVariantList readList(const QString &key) const;
    void writeList(const QString &key, const QVariantList &list) const;

    QSettings *m_settings;
};

#endif // APPSETTINGS_H
