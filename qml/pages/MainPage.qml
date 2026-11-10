import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api
import Harbour.SwissTransport 1.0

Page {
    id: root

    property var fromStation: null
    property var toStation: null
    property date searchDate: new Date()

    AppSettings { id: settings }
    property var recentList: []
    property var favStations: []

    function setStation(field, station) {
        if (field === "from") root.fromStation = station;
        else root.toStation = station;
    }

    function search() {
        if (!fromStation || !toStation) return;
        settings.addRecent({ fromName: fromStation.name, toName: toStation.name });
        pageStack.push(Qt.resolvedUrl("ConnectionsPage.qml"), {
            fromStation: fromStation,
            toStation: toStation,
            dateStr: Qt.formatDate(searchDate, "yyyy-MM-dd"),
            timeStr: Qt.formatTime(searchDate, "hh:mm")
        });
    }

    function reloadLists() {
        recentList = settings.recents();
        favStations = settings.favourites();
    }

    onStatusChanged: {
        if (status === PageStatus.Active) reloadLists();
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.itemSizeLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Nearby stations")
                onClicked: pageStack.push(Qt.resolvedUrl("NearbyPage.qml"))
            }
            MenuItem {
                text: qsTr("Favourites")
                onClicked: pageStack.push(Qt.resolvedUrl("FavouritesPage.qml"))
            }
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }

        Column {
            id: contentColumn
            width: parent.width
            spacing: 0

            PageHeader {
                title: qsTr("Swiss Transport")
            }

            // ---- From -----------------------------------------------------
            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeMedium
                onClicked: pageStack.push(Qt.resolvedUrl("StationPickerPage.qml"),
                                          { caller: root, field: "from" })
                Label {
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: root.fromStation ? root.fromStation.name : qsTr("From…")
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            // ---- swap -----------------------------------------------------
            Row {
                width: parent.width
                layoutDirection: Qt.RightToLeft
                IconButton {
                    icon.source: "image://theme/icon-m-repeat"
                    onClicked: {
                        var f = root.fromStation
                        root.fromStation = root.toStation
                        root.toStation = f
                    }
                }
            }

            // ---- To -------------------------------------------------------
            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeMedium
                onClicked: pageStack.push(Qt.resolvedUrl("StationPickerPage.qml"),
                                          { caller: root, field: "to" })
                Label {
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: root.toStation ? root.toStation.name : qsTr("To…")
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                }
            }

            // ---- date & time ----------------------------------------------
            Row {
                width: parent.width
                ValueButton {
                    width: parent.width / 2
                    label: qsTr("Date")
                    value: Qt.formatDate(root.searchDate, "ddd dd MMM")
                    onClicked: pageStack.push(datePicker)
                }
                ValueButton {
                    width: parent.width / 2
                    label: qsTr("Time")
                    value: Qt.formatTime(root.searchDate, "hh:mm")
                    onClicked: pageStack.push(timePicker)
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                preferredWidth: Theme.buttonWidthLarge
                text: qsTr("Search connections")
                enabled: root.fromStation && root.toStation
                onClicked: root.search()
            }

            // ---- favourites shortcut --------------------------------------
            SectionHeader {
                text: qsTr("Favourite stations")
                visible: favStations.length > 0
            }
            Repeater {
                model: favStations
                BackgroundItem {
                    width: parent.width
                    height: Theme.itemSizeMedium
                    onClicked: pageStack.push(Qt.resolvedUrl("StationboardPage.qml"),
                                              { station: modelData })
                    Label {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: modelData.name
                        truncationMode: TruncationMode.Fade
                        color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                }
            }

            // ---- recent searches ------------------------------------------
            SectionHeader {
                text: qsTr("Recent searches")
                visible: recentList.length > 0
            }
            Column {
                width: parent.width
                Repeater {
                    model: recentList
                    BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeMedium
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("ConnectionsPage.qml"), {
                                fromStation: { name: modelData.fromName },
                                toStation: { name: modelData.toName },
                                dateStr: Qt.formatDate(new Date(), "yyyy-MM-dd"),
                                timeStr: Qt.formatTime(new Date(), "hh:mm")
                            })
                        }
                        Label {
                            x: Theme.horizontalPageMargin
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 2 * Theme.horizontalPageMargin
                            text: modelData.fromName + " → " + modelData.toName
                            truncationMode: TruncationMode.Fade
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component {
        id: datePicker
        DatePickerDialog {
            date: root.searchDate
            onAccepted: {
                var d = new Date(date)
                d.setHours(root.searchDate.getHours(), root.searchDate.getMinutes())
                root.searchDate = d
            }
        }
    }

    Component {
        id: timePicker
        TimePickerDialog {
            hour: root.searchDate.getHours()
            minute: root.searchDate.getMinutes()
            onAccepted: {
                var d = new Date(root.searchDate)
                d.setHours(hour, minute)
                root.searchDate = d
            }
        }
    }
}
