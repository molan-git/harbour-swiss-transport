#ifndef TRANSPORTCLIENT_H
#define TRANSPORTCLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QAbstractListModel>
#include <QVariantMap>

class TransportListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:

    enum Roles {
        TitleRole = Qt::UserRole + 1,
        SubtitleRole,
        IdentifierRole,
        TimeRole,
        PlatformRole,
        DelayRole
    };

    explicit TransportListModel(QObject *parent = 0);

    int rowCount(
        const QModelIndex &parent = QModelIndex()
    ) const;

    int count() const;

    QVariant data(
        const QModelIndex &index,
        int role = Qt::DisplayRole
    ) const;

    QHash<int, QByteArray> roleNames() const;

    void clear();

    void addItem(const QVariantMap &item);

private:

    QList<QVariantMap> m_items;

signals:

    void countChanged();
};


class TransportClient : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
        TransportListModel *stationModel
        READ stationModel CONSTANT
    )

    Q_PROPERTY(
        TransportListModel *departureModel
        READ departureModel CONSTANT
    )

    Q_PROPERTY(
        TransportListModel *connectionModel
        READ connectionModel CONSTANT
    )

    Q_PROPERTY(
        bool busy
        READ busy
        NOTIFY busyChanged
    )

    Q_PROPERTY(
        QString errorMessage
        READ errorMessage
        NOTIFY errorMessageChanged
    )

public:

    explicit TransportClient(QObject *parent = 0);

    TransportListModel *stationModel();
    TransportListModel *departureModel();
    TransportListModel *connectionModel();

    bool busy() const;
    QString errorMessage() const;

    Q_INVOKABLE void searchStations(
        const QString &query
    );

    Q_INVOKABLE void loadDepartures(
        const QString &stationId,
        const QString &stationName
    );

    Q_INVOKABLE void searchConnections(
        const QString &from,
        const QString &to
    );

signals:

    void busyChanged();
    void errorMessageChanged();

private slots:

    void handleReply();

private:

    enum RequestType {
        LocationRequest,
        StationboardRequest,
        ConnectionRequest
    };

    void setBusy(bool value);
    void setErrorMessage(const QString &message);

    QNetworkAccessManager m_manager;

    TransportListModel m_stationModel;
    TransportListModel m_departureModel;
    TransportListModel m_connectionModel;

    bool m_busy;
    int m_activeRequests;

    QString m_errorMessage;
};

#endif
