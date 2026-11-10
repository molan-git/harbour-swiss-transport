import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api

// Two-step page: first search a reference station, then the page lists
// stations around it with their distance.
Page {
    id: root

    property var refStation: null
    property var nearby: []
    property var searchResults: []
    property bool loading: false
    property string errorText: ""

    function setStation(field, station) {
        refStation = station
        searchResults = []
        nearby = []
        errorText = ""
        loading = true
        Api.nearby(station.coordinate.y, station.coordinate.x, function(list) {
            // filter out the reference station itself
            var res = []
            for (var i = 0; i < list.length; i++) {
                if (list[i].id !== station.id) res.push(list[i])
            }
            nearby = res
            loading = false
        }, function(err) {
            errorText = err
            loading = false
        })
    }

    function search() {
        if (searchField.text.length < 2) { searchResults = []; return }
        Api.searchStations(searchField.text, function(list) {
            root.searchResults = list
        }, function(err) { root.errorText = err })
    }

    SilicaListView {
        anchors.fill: parent

        header: Column {
            width: parent.width
            PageHeader { title: qsTr("Nearby stations") }

            SearchField {
                id: searchField
                width: parent.width
                placeholderText: root.refStation
                                  ? root.refStation.name
                                  : qsTr("Search reference station…")
                onTextChanged: timer.restart()
                EnterKey.onClicked: { timer.stop(); root.search(); focus = false }
                EnterKey.iconSource: "image://theme/icon-m-search"
            }
        }

        Timer {
            id: timer
            interval: 350
            onTriggered: root.search()
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: root.loading
            visible: running
            size: BusyIndicatorSize.Large
        }

        ViewPlaceholder {
            enabled: !root.refStation && !root.loading && root.searchResults.length === 0
            text: qsTr("Pick a reference station")
            hintText: qsTr("Nearby stations are shown around it")
        }

        delegate: BackgroundItem {
            id: item
            property var st: modelData

            // first stage: tap a search result to make it the reference station
            // second stage: tap a nearby station to open its departure board
            onClicked: {
                if (!root.refStation)
                    root.setStation("ref", st)
                else
                    pageStack.push(Qt.resolvedUrl("StationboardPage.qml"), { station: st })
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: st.name
                    truncationMode: TruncationMode.Fade
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    visible: root.refStation && st.coordinate
                    text: root.refStation && st.coordinate
                          ? Api.fmtDistance(Api.distance(root.refStation, st)) : ""
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
        }

        model: root.refStation ? root.nearby
             : root.searchResults

        VerticalScrollDecorator {}
    }
}
