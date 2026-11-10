import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api
import Harbour.SwissTransport 1.0

CoverBackground {
    id: cover

    AppSettings { id: settings }

    property var favs: []
    property var homeStation: null
    property var departures: []
    property bool loading: false

    function refresh() {
        favs = settings.favourites()
        if (favs.length === 0) { departures = []; return }
        homeStation = favs[0]
        loading = true
        var key = homeStation.id ? homeStation.id : homeStation.name
        Api.stationboard(key, 5, 0, function(list) {
            departures = list
            loading = false
        }, function() { loading = false })
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 60000
        running: cover.status === Cover.Activating || cover.status === Cover.Activated
        onTriggered: cover.refresh()
    }

    Column {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        y: Theme.paddingLarge
        spacing: Theme.paddingMedium

        Label {
            width: parent.width
            text: homeStation ? homeStation.name : qsTr("Swiss Transport")
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.highlightColor
            truncationMode: TruncationMode.Fade
        }

        Label {
            width: parent.width
            visible: !homeStation && !loading
            text: qsTr("Add a favourite station to see its departures here")
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            wrapMode: Text.WordWrap
        }

        BusyIndicator {
            running: cover.loading
            visible: running
            size: BusyIndicatorSize.Small
        }

        Repeater {
            model: cover.departures
            Row {
                spacing: Theme.paddingMedium
                Label {
                    text: modelData.stop && modelData.stop.departure
                          ? Api.hhmm(modelData.stop.departure) : ""
                    color: (modelData.stop && Api.delayOf(modelData.stop) > 0)
                           ? "red" : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                Label {
                    text: modelData.to || ""
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    width: cover.width - 140
                }
            }
        }
    }
}
