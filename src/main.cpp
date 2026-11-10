#include <sailfishapp.h>

#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>

#include "appsettings.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app =
        SailfishApp::application(argc, argv);

    QQuickView *view =
        SailfishApp::createView();

    qmlRegisterType<AppSettings>(
        "Harbour.SwissTransport", 1, 0, "AppSettings");

    view->setSource(
        SailfishApp::pathTo("qml/harbour-swiss-transport.qml")
    );

    view->show();

    return app->exec();
}
