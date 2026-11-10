#include "appsettings.h"
#include <QSettings>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

static const int MAX_RECENTS = 6;

AppSettings::AppSettings(QObject *parent)
    : QObject(parent),
      m_settings(new QSettings(QStringLiteral("harbour-swiss-transport"),
                               QStringLiteral("swisstransport"), this))
{
}

AppSettings::~AppSettings()
{
}

QVariantList AppSettings::readList(const QString &key) const
{
    const QString raw = m_settings->value(key).toString();
    if (raw.isEmpty())
        return QVariantList();
    const QJsonDocument doc = QJsonDocument::fromJson(raw.toUtf8());
    if (!doc.isArray())
        return QVariantList();
    return doc.array().toVariantList();
}

void AppSettings::writeList(const QString &key, const QVariantList &list) const
{
    QJsonArray arr;
    for (const QVariant &v : list)
        arr.append(QJsonObject::fromVariantMap(v.toMap()));
    m_settings->setValue(key, QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact)));
}

QVariantList AppSettings::favourites() const
{
    return readList(QStringLiteral("favourites"));
}

bool AppSettings::isFavourite(const QString &id) const
{
    const QVariantList favs = favourites();
    for (const QVariant &v : favs) {
        if (v.toMap().value("id").toString() == id)
            return true;
    }
    return false;
}

void AppSettings::addFavourite(const QVariantMap &station)
{
    if (isFavourite(station.value("id").toString()))
        return;
    QVariantList favs = favourites();
    favs.prepend(station);
    writeList(QStringLiteral("favourites"), favs);
}

void AppSettings::removeFavourite(const QString &id)
{
    QVariantList favs;
    const QVariantList all = favourites();
    for (const QVariant &v : all) {
        if (v.toMap().value("id").toString() != id)
            favs.append(v);
    }
    writeList(QStringLiteral("favourites"), favs);
}

QVariantList AppSettings::recents() const
{
    return readList(QStringLiteral("recents"));
}

void AppSettings::addRecent(const QVariantMap &journey)
{
    QVariantList rec = recents();
    // move to front if identical journey already exists
    const QString sig = journey.value("fromName").toString()
                      + QStringLiteral("|")
                      + journey.value("toName").toString();
    QVariantList kept;
    for (const QVariant &v : rec) {
        const QString s = v.toMap().value("fromName").toString()
                        + QStringLiteral("|")
                        + v.toMap().value("toName").toString();
        if (s != sig)
            kept.append(v);
    }
    kept.prepend(journey);
    while (kept.size() > MAX_RECENTS)
        kept.removeLast();
    writeList(QStringLiteral("recents"), kept);
}

void AppSettings::removeRecent(int index)
{
    QVariantList rec = recents();
    if (index >= 0 && index < rec.size()) {
        rec.removeAt(index);
        writeList(QStringLiteral("recents"), rec);
    }
}

void AppSettings::clearRecents()
{
    writeList(QStringLiteral("recents"), QVariantList());
}
