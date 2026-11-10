import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api
import Harbour.SwissTransport 1.0

Page {
    id: root

    property var station
    property int offset: 0
    property var board: []
    property bool loading: false
    property string errorText: ""

    AppSettings { id: settings }

    function reload() {
        if (!station) return
        errorText = ""
        loading = true
        var key = station.id ? station.id : station.name
        Api.stationboard(key, 30, offset, function(list) {
            board = list
            loading = false
        }, function(err) {
            errorText = err
            loading = false
        })
    }

    Component.onCompleted: reload()

    SilicaListView {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: settings.isFavourite(root.station ? root.station.id : "")
                      ? qsTr("Remove from favourites")
                      : qsTr("Add to favourites")
                onClicked: {
                    if (settings.isFavourite(root.station.id))
                        settings.removeFavourite(root.station.id)
                    else
                        settings.addFavourite(root.station)
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: root.reload()
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Load more departures")
                onClicked: { root.offset += 30; root.reload() }
            }
        }

        header: Column {
            width: parent.width
            PageHeader { title: root.station ? root.station.name : "" }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Departures")
                color: Theme.secondaryColor
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: root.loading
            visible: running
            size: BusyIndicatorSize.Large
        }

        ViewPlaceholder {
            enabled: !root.loading && root.board.length === 0 && root.errorText === ""
            text: qsTr("No departures found")
        }

        ViewPlaceholder {
            enabled: root.errorText !== ""
            text: qsTr("Request failed")
            hintText: root.errorText
        }

        delegate: BackgroundItem {
            id: item
            property var b: modelData

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall

                Row {
                    spacing: Theme.paddingMedium
                    Label {
                        text: b.stop && b.stop.departure ? Api.hhmm(b.stop.departure) : ""
                        color: (b.stop && Api.delayOf(b.stop) > 0) ? "red" : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }
                    Label {
                        text: (b.stop && Api.delayOf(b.stop) > 0)
                              ? qsTr("+%1").arg(Api.delayOf(b.stop)) : ""
                        color: "red"
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        visible: b.stop && b.stop.cancelled
                        text: qsTr("Cancelled")
                        color: "red"
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Row {
                    spacing: Theme.paddingMedium
                    Label {
                        text: {
                            var p = b.pass && b.pass.length > 0 ? b.pass[0] : null
                            if (p && p.line_label) return p.line_label
                            var cat = p ? p.category : (b.category || "")
                            var num = b.number || ""
                            return (cat + " " + num).trim()
                        }
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    Label {
                        width: parent.width - 120
                        text: b.to || ""
                        truncationMode: TruncationMode.Fade
                        color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                }

                Label {
                    visible: b.stop && b.stop.platform
                    text: qsTr("Platform %1").arg(b.stop.platform)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
        }

        model: board
        VerticalScrollDecorator {}
    }
}
