#include <sailfishapp.h>

#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>

#include "transportclient.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app =
        SailfishApp::application(argc, argv);

    QQuickView *view =
        SailfishApp::createView();

    TransportClient transportClient;

    view->rootContext()->setContextProperty(
        "transportClient",
        &transportClient
    );

    view->setSource(
        SailfishApp::pathTo("qml/harbour-swiss-transport.qml")
    );

    view->show();

    return app->exec();
}
