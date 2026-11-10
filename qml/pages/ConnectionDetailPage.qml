import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api

Page {
    id: root

    property var connection

    property var legList: []   // built from connection.sections

    // Hidden reference labels: measure the exact width of the widest
    // possible value at the actual font size. Their implicit width is the
    // column width -> wide enough on every density, never overlapping.
    Label {
        id: timeMetrics      // "00:00" at fontSizeMedium (dep/arr rows)
        visible: false
        text: "00:00"
        font.pixelSize: Theme.fontSizeMedium
    }
    Label {
        id: platMetrics      // "Pl. 88" at fontSizeSmall
        visible: false
        text: "Pl. 88"
        font.pixelSize: Theme.fontSizeSmall
    }
    Label {
        id: timeMetricsSm    // "00:00" at fontSizeExtraSmall (intermediate stops)
        visible: false
        text: "00:00"
        font.pixelSize: Theme.fontSizeExtraSmall
    }
    Label {
        id: platMetricsSm
        visible: false
        text: "Pl. 88"
        font.pixelSize: Theme.fontSizeExtraSmall
    }

    function buildLegs() {
        var legs = []
        if (!connection || !connection.sections) return legs
        for (var i = 0; i < connection.sections.length; i++) {
            var s = connection.sections[i]
            if (s.journey) {
                legs.push({
                    type: "journey",
                    label: Api.lineLabel(s),
                    direction: s.journey.to ? s.journey.to : "",
                    fromName: s.departure ? s.departure.station.name : "",
                    toName: s.arrival ? s.arrival.station.name : "",
                    dep: s.departure ? s.departure.departure : "",
                    arr: s.arrival ? s.arrival.arrival : "",
                    depDelay: s.departure ? Api.delayOf(s.departure, "departure") : 0,
                    arrDelay: s.arrival ? Api.delayOf(s.arrival, "arrival") : 0,
                    depPlatform: (s.departure && s.departure.platform) ? String(s.departure.platform) : "",
                    arrPlatform: (s.arrival && s.arrival.platform) ? String(s.arrival.platform) : "",
                    stops: s.journey.passList ? s.journey.passList : [],
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
        id: listView
        anchors.fill: parent

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: Api.hhmm(connection.from.departure) + " → "
                       + Api.hhmm(connection.to.arrival)
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: connection.from.station.name + " → " + connection.to.station.name
                      + "\n" + qsTr("Total %1").arg(Api.fmtDuration(Api.connectionMinutes(connection)))
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                truncationMode: TruncationMode.Fade
            }
        }

        delegate: Item {
            id: item

            property var leg: modelData

            // content-driven height: never overlaps
            width: listView.width
            height: legCard.height + 2 * Theme.paddingMedium

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (item.leg.type === "journey" && item.leg.stops.length > 2) {
                        var l = root.legList[index]
                        l.expanded = !l.expanded
                        root.legList = root.legList.slice()
                    }
                }
            }

            Column {
                id: legCard
                x: Theme.horizontalPageMargin
                width: item.width - 2 * Theme.horizontalPageMargin
                y: Theme.paddingMedium
                spacing: Theme.paddingSmall

                // ---------- walk leg ----------
                Column {
                    width: legCard.width
                    visible: item.leg.type === "walk"
                    spacing: Theme.paddingSmall

                    Label {
                        width: legCard.width
                        text: qsTr("Walk %1 min").arg(item.leg.minutes)
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    Label {
                        width: legCard.width
                        text: Api.hhmm(item.leg.dep) + "  " + item.leg.fromName
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: legCard.width
                        text: Api.hhmm(item.leg.arr) + "  " + item.leg.toName
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                    }
                }

                // ---------- train / bus / ship leg ----------
                Column {
                    width: legCard.width
                    visible: item.leg.type === "journey"
                    spacing: Theme.paddingSmall

                    Row {
                        width: legCard.width
                        spacing: Theme.paddingSmall
                        Label {
                            width: legCard.width * 0.4
                            text: item.leg.label
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeMedium
                            truncationMode: TruncationMode.Fade
                        }
                        Label {
                            width: legCard.width * 0.6 - Theme.paddingSmall
                            horizontalAlignment: Text.AlignRight
                            text: qsTr("to %1").arg(item.leg.direction)
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            truncationMode: TruncationMode.Fade
                        }
                    }

                    // departure row
                    Row {
                        width: legCard.width
                        spacing: Theme.paddingSmall
                        Label {
                            width: timeMetrics.width
                            text: Api.hhmm(item.leg.dep)
                            color: item.leg.depDelay > 0 ? "red" : Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        Label {
                            width: platMetrics.width
                            horizontalAlignment: Text.AlignRight
                            text: item.leg.depPlatform
                                ? qsTr("Pl. %1").arg(item.leg.depPlatform) : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            truncationMode: TruncationMode.Elide
                        }
                        Label {
                            width: parent.width - timeMetrics.width - platMetrics.width
                                   - 2 * Theme.paddingSmall
                            text: item.leg.fromName
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                            truncationMode: TruncationMode.Fade
                        }
                    }

                    // arrival row
                    Row {
                        width: legCard.width
                        spacing: Theme.paddingSmall
                        Label {
                            width: timeMetrics.width
                            text: Api.hhmm(item.leg.arr)
                            color: item.leg.arrDelay > 0 ? "red" : Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        Label {
                            width: platMetrics.width
                            horizontalAlignment: Text.AlignRight
                            text: item.leg.arrPlatform
                                ? qsTr("Pl. %1").arg(item.leg.arrPlatform) : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            truncationMode: TruncationMode.Elide
                        }
                        Label {
                            width: parent.width - timeMetrics.width - platMetrics.width
                                   - 2 * Theme.paddingSmall
                            text: item.leg.toName
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                            truncationMode: TruncationMode.Fade
                        }
                    }

                    // delay warning
                    Label {
                        width: legCard.width
                        visible: item.leg.depDelay > 0 || item.leg.arrDelay > 0
                        text: {
                            var parts = []
                            if (item.leg.depDelay > 0)
                                parts.push(qsTr("departs %1 min late").arg(item.leg.depDelay))
                            if (item.leg.arrDelay > 0)
                                parts.push(qsTr("arrives %1 min late").arg(item.leg.arrDelay))
                            return parts.join(", ")
                        }
                        color: "red"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }

                    // stops toggle
                    Label {
                        width: legCard.width
                        visible: item.leg.stops.length > 2
                        text: item.leg.expanded
                              ? qsTr("Hide %1 intermediate stops").arg(item.leg.stops.length - 2)
                              : qsTr("Show %1 intermediate stops").arg(item.leg.stops.length - 2)
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }

                    // intermediate stops
                    Column {
                        width: legCard.width
                        visible: item.leg.expanded
                        spacing: Theme.paddingSmall

                        Repeater {
                            model: item.leg.stops.length > 2
                                   ? item.leg.stops.slice(1, item.leg.stops.length - 1)
                                   : []
                            Row {
                                width: legCard.width
                                spacing: Theme.paddingSmall
                                Label {
                                    width: timeMetricsSm.width
                                    text: modelData.departure
                                          ? Api.hhmm(modelData.departure)
                                          : Api.hhmm(modelData.arrival)
                                    color: Api.delayOf(modelData) > 0 ? "red" : Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                }
                                Label {
                                    width: platMetricsSm.width
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData.platform ? String(modelData.platform) : ""
                                    color: Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    truncationMode: TruncationMode.Elide
                                }
                                Label {
                                    width: parent.width - timeMetricsSm.width
                                           - platMetricsSm.width - 2 * Theme.paddingSmall
                                    text: modelData.station ? modelData.station.name : ""
                                    color: Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    truncationMode: TruncationMode.Fade
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
