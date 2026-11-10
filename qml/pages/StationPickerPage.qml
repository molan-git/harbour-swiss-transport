import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api

Page {
    id: root

    // set by the caller: { caller: pageInstance, field: "from"|"to"|"ref" }
    property var caller
    property string field

    property var stations: []
    property bool loading: false
    property string errorText: ""

    function search() {
        errorText = ""
        if (searchField.text.length < 2) {
            stations = []
            return
        }
        loading = true
        Api.searchStations(searchField.text, function(list) {
            stations = list
            loading = false
        }, function(err) {
            errorText = err
            loading = false
        })
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: root.search()
            }
        }

        header: Column {
            width: parent.width
            PageHeader { title: qsTr("Select station") }
            SearchField {
                id: searchField
                width: parent.width
                placeholderText: qsTr("Station name…")
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
            enabled: !root.loading && root.stations.length === 0 && root.errorText === ""
            text: qsTr("No stations found")
            hintText: qsTr("Type at least two letters")
        }

        ViewPlaceholder {
            enabled: root.errorText !== ""
            text: qsTr("Search failed")
            hintText: root.errorText
        }

        delegate: BackgroundItem {
            id: item
            property var station: modelData

            onClicked: {
                if (root.caller && root.caller.setStation) {
                    root.caller.setStation(root.field, station)
                    pageStack.pop()
                }
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: station.name
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    width: parent.width
                    visible: station.id !== undefined
                    text: station.id ? qsTr("SBB station ID: %1").arg(station.id) : ""
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
        }

        model: stations
        VerticalScrollDecorator {}
    }
}
