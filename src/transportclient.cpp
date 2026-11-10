#include "transportclient.h"

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QDateTime>

static const QString API_BASE =
    QStringLiteral("https://transport.opendata.ch/v1/");


TransportListModel::TransportListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int TransportListModel::rowCount(
    const QModelIndex &parent
) const
{
    if (parent.isValid())
        return 0;

    return m_items.count();
}

int TransportListModel::count() const
{
    return m_items.count();
}

QVariant TransportListModel::data(
    const QModelIndex &index,
    int role
) const
{
    if (!index.isValid() ||
        index.row() < 0 ||
        index.row() >= m_items.count()) {
        return QVariant();
    }

    const QVariantMap item =
        m_items.at(index.row());

    switch (role) {

    case TitleRole:
        return item.value("title");

    case SubtitleRole:
        return item.value("subtitle");

    case IdentifierRole:
        return item.value("identifier");

    case TimeRole:
        return item.value("time");

    case PlatformRole:
        return item.value("platform");

    case DelayRole:
        return item.value("delay");

    default:
        return QVariant();
    }
}

QHash<int, QByteArray>
TransportListModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[TitleRole] = "title";
    roles[SubtitleRole] = "subtitle";
    roles[IdentifierRole] = "identifier";
    roles[TimeRole] = "time";
    roles[PlatformRole] = "platform";
    roles[DelayRole] = "delay";

    return roles;
}

void TransportListModel::clear()
{
    beginResetModel();
    m_items.clear();
    endResetModel();

    emit countChanged();
}

void TransportListModel::addItem(
    const QVariantMap &item
)
{
    const int position = m_items.count();

    beginInsertRows(
        QModelIndex(),
        position,
        position
    );

    m_items.append(item);

    endInsertRows();

    emit countChanged();
}


TransportClient::TransportClient(QObject *parent)
    : QObject(parent),
      m_stationModel(this),
      m_departureModel(this),
      m_connectionModel(this),
      m_busy(false),
      m_activeRequests(0)
{
}

TransportListModel *
TransportClient::stationModel()
{
    return &m_stationModel;
}

TransportListModel *
TransportClient::departureModel()
{
    return &m_departureModel;
}

TransportListModel *
TransportClient::connectionModel()
{
    return &m_connectionModel;
}

bool TransportClient::busy() const
{
    return m_busy;
}

QString TransportClient::errorMessage() const
{
    return m_errorMessage;
}

void TransportClient::setBusy(bool value)
{
    if (m_busy == value)
        return;

    m_busy = value;

    emit busyChanged();
}

void TransportClient::setErrorMessage(
    const QString &message
)
{
    if (m_errorMessage == message)
        return;

    m_errorMessage = message;

    emit errorMessageChanged();
}


/*
 * Search for stations and stops.
 */

void TransportClient::searchStations(
    const QString &query
)
{
    const QString search = query.trimmed();

    if (search.isEmpty()) {
        setErrorMessage("Please enter a station name.");
        return;
    }

    setErrorMessage(QString());

    m_stationModel.clear();

    QUrl url(API_BASE + "locations");

    QUrlQuery parameters;

    parameters.addQueryItem(
        "query",
        search
    );

    parameters.addQueryItem(
        "type",
        "station"
    );

    url.setQuery(parameters);

    QNetworkRequest request(url);

    QNetworkReply *reply =
        m_manager.get(request);

    reply->setProperty(
        "requestType",
        LocationRequest
    );

    connect(
        reply,
        SIGNAL(finished()),
        this,
        SLOT(handleReply())
    );

    ++m_activeRequests;
    setBusy(true);
}


/*
 * Load departures from a selected station.
 */

void TransportClient::loadDepartures(
    const QString &stationId,
    const QString &stationName
)
{
    if (stationId.isEmpty() &&
        stationName.trimmed().isEmpty()) {

        setErrorMessage("No station selected.");
        return;
    }

    setErrorMessage(QString());

    m_departureModel.clear();

    QUrl url(API_BASE + "stationboard");

    QUrlQuery parameters;

    if (!stationId.isEmpty()) {
        parameters.addQueryItem(
            "id",
            stationId
        );
    } else {
        parameters.addQueryItem(
            "station",
            stationName
        );
    }

    parameters.addQueryItem("limit", "20");
    parameters.addQueryItem("type", "departure");

    url.setQuery(parameters);

    QNetworkRequest request(url);

    QNetworkReply *reply =
        m_manager.get(request);

    reply->setProperty(
        "requestType",
        StationboardRequest
    );

    connect(
        reply,
        SIGNAL(finished()),
        this,
        SLOT(handleReply())
    );

    ++m_activeRequests;
    setBusy(true);
}


/*
 * Search for connections between two locations.
 */

void TransportClient::searchConnections(
    const QString &from,
    const QString &to
)
{
    const QString origin = from.trimmed();
    const QString destination = to.trimmed();

    if (origin.isEmpty() ||
        destination.isEmpty()) {

        setErrorMessage(
            "Enter both departure and destination."
        );

        return;
    }

    setErrorMessage(QString());

    m_connectionModel.clear();

    QUrl url(API_BASE + "connections");

    QUrlQuery parameters;

    parameters.addQueryItem("from", origin);
    parameters.addQueryItem("to", destination);
    parameters.addQueryItem("limit", "8");

    url.setQuery(parameters);

    QNetworkRequest request(url);

    QNetworkReply *reply =
        m_manager.get(request);

    reply->setProperty(
        "requestType",
        ConnectionRequest
    );

    connect(
        reply,
        SIGNAL(finished()),
        this,
        SLOT(handleReply())
    );

    ++m_activeRequests;
    setBusy(true);
}


/*
 * Handle completed HTTP requests.
 */

void TransportClient::handleReply()
{
    QNetworkReply *reply =
        qobject_cast<QNetworkReply *>(sender());

    if (!reply)
        return;

    const int requestType =
        reply->property("requestType").toInt();

    const QByteArray response =
        reply->readAll();

    if (reply->error() != QNetworkReply::NoError) {

        setErrorMessage(
            reply->errorString()
        );

    } else {

        QJsonParseError parseError;

        const QJsonDocument document =
            QJsonDocument::fromJson(
                response,
                &parseError
            );

        if (parseError.error !=
            QJsonParseError::NoError ||
            !document.isObject()) {

            setErrorMessage(
                "The transport service returned invalid data."
            );

        } else {

            const QJsonObject root =
                document.object();

            /*
             * Station search results.
             */

            if (requestType == LocationRequest) {

                const QJsonArray stations =
                    root.value("stations").toArray();

                for (int i = 0;
                     i < stations.size();
                     ++i) {

                    const QJsonObject station =
                        stations.at(i).toObject();

                    QVariantMap item;

                    item["title"] =
                        station.value("name").toString();

                    item["subtitle"] =
                        station.value("type").toString();

                    item["identifier"] =
                        station.value("id").toString();

                    m_stationModel.addItem(item);
                }

                if (stations.isEmpty()) {
                    setErrorMessage(
                        "No stations found."
                    );
                }
            }


            /*
             * Stationboard results.
             */

            if (requestType == StationboardRequest) {

                const QJsonArray departures =
                    root.value("stationboard").toArray();

                for (int i = 0;
                     i < departures.size();
                     ++i) {

                    const QJsonObject journey =
                        departures.at(i).toObject();

                    const QJsonObject stop =
                        journey.value("stop").toObject();

                    QVariantMap item;

                    const QString category =
                        journey.value("category").toString();

                    const QString number =
                        journey.value("number").toString();

                    item["title"] =
                        category + " " + number;

                    item["subtitle"] =
                        "To " +
                        journey.value("to").toString();

                    item["platform"] =
                        stop.value("platform").toString();

                    QString departure =
                        stop.value("departure").toString();

                    QDateTime departureTime =
                        QDateTime::fromString(
                            departure,
                            Qt::ISODate
                        );

                    item["time"] =
                        departureTime.isValid()
                        ? departureTime.toLocalTime()
                              .toString("HH:mm")
                        : QString("--:--");

                    const QJsonValue delay =
                        stop.value("delay");

                    item["delay"] =
                        delay.isNull()
                        ? QString()
                        : QString::number(delay.toInt());

                    m_departureModel.addItem(item);
                }

                if (departures.isEmpty()) {
                    setErrorMessage(
                        "No departures found."
                    );
                }
            }


            /*
             * Journey planner results.
             */

            if (requestType == ConnectionRequest) {

                const QJsonArray connections =
                    root.value("connections").toArray();

                for (int i = 0;
                     i < connections.size();
                     ++i) {

                    const QJsonObject connection =
                        connections.at(i).toObject();

                    const QJsonObject from =
                        connection.value("from").toObject();

                    const QJsonObject to =
                        connection.value("to").toObject();

                    const QJsonObject fromStation =
                        from.value("station").toObject();

                    const QJsonObject toStation =
                        to.value("station").toObject();

                    const QString departure =
                        from.value("departure").toString();

                    const QString arrival =
                        to.value("arrival").toString();

                    QDateTime departureTime =
                        QDateTime::fromString(
                            departure,
                            Qt::ISODate
                        );

                    QDateTime arrivalTime =
                        QDateTime::fromString(
                            arrival,
                            Qt::ISODate
                        );

                    QString duration;

                    if (departureTime.isValid() &&
                        arrivalTime.isValid()) {

                        qint64 minutes =
                            departureTime.secsTo(arrivalTime) / 60;

                        duration =
                            QString("%1 h %2 min")
                            .arg(minutes / 60)
                            .arg(minutes % 60);
                    }

                    const QJsonArray sections =
                        connection.value("sections").toArray();

                    QStringList transportNames;

                    for (int j = 0;
                         j < sections.size();
                         ++j) {

                        const QJsonObject section =
                            sections.at(j).toObject();

                        const QJsonObject journey =
                            section.value("journey").toObject();

                        if (!journey.isEmpty()) {

                            QString name =
                                journey.value("category").toString()
                                + " "
                                + journey.value("number").toString();

                            transportNames.append(name);
                        } else if (!section.value("walk").isNull()) {
                            transportNames.append("Walk");
                        }
                    }

                    QVariantMap item;

                    item["title"] =
                        departureTime.isValid()
                        ? departureTime.toLocalTime()
                              .toString("HH:mm")
                        : "--:--";

                    item["subtitle"] =
                        arrivalTime.isValid()
                        ? arrivalTime.toLocalTime()
                              .toString("HH:mm")
                        : "--:--";

                    item["identifier"] =
                        fromStation.value("name").toString()
                        + " → "
                        + toStation.value("name").toString();

                    item["time"] = duration;

                    item["platform"] =
                        transportNames.join(" · ");

                    item["delay"] = QString();

                    m_connectionModel.addItem(item);
                }

                if (connections.isEmpty()) {
                    setErrorMessage(
                        "No connections found."
                    );
                }
            }
        }
    }

    reply->deleteLater();

    --m_activeRequests;

    if (m_activeRequests <= 0) {
        m_activeRequests = 0;
        setBusy(false);
    }
}
