import QtQuick 2.0
import Sailfish.Silica 1.0
import Harbour.SwissTransport 1.0

Page {
    id: root

    AppSettings { id: settings }
    property var favs: []

    onStatusChanged: {
        if (status === PageStatus.Active) favs = settings.favourites()
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader { title: qsTr("Favourite stations") }

        ViewPlaceholder {
            enabled: favs.length === 0
            text: qsTr("No favourites yet")
            hintText: qsTr("Open a station board and use the pulley menu to add it")
        }

        delegate: BackgroundItem {
            id: item
            property var station: modelData

            RemorseItem { id: remorse }

            ContextMenu {
                id: favMenu
                MenuItem {
                    text: qsTr("Remove")
                    onClicked: remorse.execute(item, qsTr("Removing"), function() {
                        settings.removeFavourite(station.id)
                        root.favs = settings.favourites()
                    })
                }
            }

            onPressAndHold: favMenu.show(item)

            onClicked: pageStack.push(Qt.resolvedUrl("StationboardPage.qml"),
                                      { station: station })

            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: station.name
                truncationMode: TruncationMode.Fade
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }

        model: favs
        VerticalScrollDecorator {}
    }
}
