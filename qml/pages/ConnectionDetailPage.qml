import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api

Page {
    id: root

    property var connection

    property var legList: []   // built from connection.sections

    function buildLegs() {
        var legs = []
        if (!connection || !connection.sections) return legs
        for (var i = 0; i < connection.sections.length; i++) {
            var s = connection.sections[i]
            if (s.journey) {
                var stops = []
                if (s.journey.passList) {
                    for (var j = 0; j < s.journey.passList.length; j++)
                        stops.push(s.journey.passList[j])
                }
                legs.push({
                    type: "journey",
                    label: Api.lineLabel(s),
                    fromName: s.departure ? s.departure.station.name : "",
                    toName: s.arrival ? s.arrival.station.name : "",
                    dep: s.departure ? s.departure.departure : "",
                    arr: s.arrival ? s.arrival.arrival : "",
                    depDelay: s.departure ? Api.delayOf(s.departure) : 0,
                    arrDelay: s.arrival ? Api.delayOf(s.arrival) : 0,
                    depPlatform: s.departure && s.departure.platform ? s.departure.platform : "",
                    arrPlatform: s.arrival && s.arrival.platform ? s.arrival.platform : "",
                    stops: stops,
                    expanded: false
                })
            } else if (s.walk) {
                legs.push({
                    type: "walk",
                    minutes: Api.walkMinutes(s.walk),
                    fromName: s.departure ? s.departure.station.name : "",
                    toName: s.arrival ? s.arrival.station.name : "",
                    dep: s.departure ? s.departure.departure : "",
                    arr: s.arrival ? s.arrival.arrival : ""
                })
            }
        }
        return legs
    }

    onConnectionChanged: legList = buildLegs()
    Component.onCompleted: legList = buildLegs()

    SilicaListView {
        anchors.fill: parent

        header: Column {
            width: parent.width
            PageHeader {
                title: Api.hhmm(connection.from.departure) + " → "
                       + Api.hhmm(connection.to.arrival)
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: connection.from.station.name + " → " + connection.to.station.name
                      + "  ·  " + Api.fmtDuration(connection.duration / 60)
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            spacing: Theme.paddingMedium
        }

        delegate: BackgroundItem {
            id: item
            property var leg: modelData
            height: legColumn.height + Theme.paddingMedium
            onClicked: {
                if (leg.type === "journey" && leg.stops.length > 2) {
                    // mutate, then reassign so the ListView rebuilds the delegates
                    var l = root.legList[index]
                    l.expanded = !l.expanded
                    root.legList = root.legList.slice()
                }
            }

            Column {
                id: legColumn
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall

                // walk section
                Column {
                    width: parent.width
                    visible: leg.type === "walk"
                    spacing: Theme.paddingSmall
                    Label {
                        text: qsTr("Walk %1 min").arg(leg.minutes)
                        color: Theme.highlightColor
                    }
                    Label {
                        text: leg.fromName + " → " + leg.toName
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                    }
                }

                // train/bus section
                Column {
                    width: parent.width
                    visible: leg.type === "journey"
                    spacing: Theme.paddingSmall

                    Label {
                        text: leg.label
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    Row {
                        spacing: Theme.paddingSmall
                        Label {
                            text: Api.hhmm(leg.dep)
                            color: leg.depDelay > 0 ? "red" : Theme.primaryColor
                        }
                        Label {
                            text: leg.fromName
                            width: root.width - Theme.horizontalPageMargin * 2 - 60
                            truncationMode: TruncationMode.Fade
                            color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            text: leg.depPlatform ? qsTr("Pl. %1").arg(leg.depPlatform) : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Row {
                        spacing: Theme.paddingSmall
                        Label {
                            text: Api.hhmm(leg.arr)
                            color: leg.arrDelay > 0 ? "red" : Theme.primaryColor
                        }
                        Label {
                            text: leg.toName
                            width: root.width - Theme.horizontalPageMargin * 2 - 60
                            truncationMode: TruncationMode.Fade
                            color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            text: leg.arrPlatform ? qsTr("Pl. %1").arg(leg.arrPlatform) : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Label {
                        visible: leg.depDelay > 0
                        text: qsTr("%1 min late").arg(leg.depDelay)
                        color: "red"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }

                    Label {
                        visible: leg.stops.length > 2
                        text: leg.expanded ? qsTr("Hide %1 intermediate stops").arg(leg.stops.length - 2)
                                           : qsTr("Show %1 intermediate stops").arg(leg.stops.length - 2)
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }

                    // intermediate stops
                    Column {
                        width: parent.width
                        visible: leg.type === "journey" && leg.expanded
                        Repeater {
                            model: {
                                var arr = leg.stops.slice(1, leg.stops.length - 1)
                                return arr
                            }
                            Row {
                                spacing: Theme.paddingSmall
                                Label {
                                    text: (modelData.departure
                                           ? Api.hhmm(modelData.departure)
                                           : Api.hhmm(modelData.arrival))
                                    color: Api.delayOf(modelData) > 0 ? "red" : Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                }
                                Label {
                                    text: modelData.station ? modelData.station.name : ""
                                    color: Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    truncationMode: TruncationMode.Fade
                                    width: root.width - Theme.horizontalPageMargin * 2 - 50
                                }
                            }
                        }
                    }
                }
            }
        }

        model: legList
        VerticalScrollDecorator {}
    }
}
