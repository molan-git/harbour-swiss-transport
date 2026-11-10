import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/Api.js" as Api

Page {
    id: root

    property var fromStation
    property var toStation
    property string dateStr
    property string timeStr

    property var connections: []
    property bool loading: false
    property string errorText: ""
    property int page: 0

    function fromKey() {
        return fromStation.id ? fromStation.id : fromStation.name
    }

    function toKey() {
        return toStation.id ? toStation.id : toStation.name
    }

    function reload() {
        errorText = ""
        loading = true

        Api.connections(fromKey(), toKey(), dateStr, timeStr, page, function(list) {
            connections = list
            loading = false
        }, function(err) {
            errorText = err
            loading = false
        })
    }

    Component.onCompleted: reload()

    SilicaListView {
        id: listView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload")
                onClicked: root.reload()
            }

            MenuItem {
                text: qsTr("Reverse direction")
                onClicked: {
                    var f = root.fromStation
                    root.fromStation = root.toStation
                    root.toStation = f
                    root.page = 0
                    root.reload()
                }
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Later connections")
                onClicked: {
                    root.page += 1
                    root.reload()
                }
            }

            MenuItem {
                text: qsTr("Earlier connections")
                enabled: root.page > 0
                onClicked: {
                    root.page -= 1
                    root.reload()
                }
            }
        }

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Connections")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: root.fromStation
                      ? root.fromStation.name + " → " + root.toStation.name
                      : ""
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                truncationMode: TruncationMode.Fade
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: root.loading
            visible: running
            size: BusyIndicatorSize.Large
        }

        ViewPlaceholder {
            enabled: !root.loading
                     && root.connections.length === 0
                     && root.errorText === ""

            text: qsTr("No connections found")
        }

        ViewPlaceholder {
            enabled: root.errorText !== ""
            text: qsTr("Request failed")
            hintText: root.errorText
        }

        delegate: BackgroundItem {
            id: item

            height: rowContent.height + 2 * Theme.paddingMedium

            property var c: modelData
            property int depDelay: c.from
                                   ? Api.delayOf(c.from, "departure") : 0
            property int arrDelay: c.to
                                   ? Api.delayOf(c.to, "arrival") : 0
            property int minutes: Api.connectionMinutes(c)

            onClicked: pageStack.push(
                Qt.resolvedUrl("ConnectionDetailPage.qml"),
                { connection: c }
            )

            // Hidden reference label for measuring HH:MM width.
            Label {
                id: timeMetrics
                visible: false
                text: "00:00"
                font.pixelSize: Theme.fontSizeLarge
            }

            Column {
                id: rowContent

                x: Theme.horizontalPageMargin
                width: item.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall

                Row {
                    width: rowContent.width
                    spacing: Theme.paddingSmall

                    Label {
                        width: timeMetrics.width
                        text: Api.hhmm(c.from.departure)
                        color: item.depDelay > 0
                               ? "red" : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    Label {
                        id: arrowLabel
                        text: "→"
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    Label {
                        width: timeMetrics.width
                        text: Api.hhmm(c.to.arrival)
                        color: item.arrDelay > 0
                               ? "red" : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    Label {
                        width: parent.width
                               - 2 * timeMetrics.width
                               - arrowLabel.implicitWidth
                               - 3 * Theme.paddingSmall

                        horizontalAlignment: Text.AlignRight

                        text: Api.fmtDuration(item.minutes)
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Elide
                    }
                }

                // Departure delay information.
                Label {
                    width: rowContent.width
                    visible: item.depDelay > 0

                    text: {
                        if (!visible)
                            return ""

                        var prog = (c.from.prognosis
                                    && c.from.prognosis.departure)
                                   ? c.from.prognosis.departure
                                   : c.from.departure

                        return qsTr("+%1 min late, departs %2")
                               .arg(item.depDelay)
                               .arg(Api.hhmm(prog))
                    }

                    color: "red"
                    font.pixelSize: Theme.fontSizeExtraSmall
                }

                // Platform information.
                Label {
                    width: rowContent.width

                    visible: (
                        c.from.platform !== undefined
                        && c.from.platform !== null
                        && c.from.platform.length > 0
                    ) || (
                        c.to.platform !== undefined
                        && c.to.platform !== null
                        && c.to.platform.length > 0
                    )

                    text: {
                        var parts = []

                        if (c.from.platform)
                            parts.push(
                                qsTr("Dep. Pl. %1").arg(c.from.platform)
                            )

                        if (c.to.platform)
                            parts.push(
                                qsTr("Arr. Pl. %1").arg(c.to.platform)
                            )

                        return parts.join("  ·  ")
                    }

                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }

                // Transport products and number of changes.
                Label {
                    width: rowContent.width

                    text: {
                        var parts = []

                        if (c.products && c.products.length > 0)
                            parts.push(c.products.join(" · "))

                        var transfers = c.transfers !== undefined
                                        ? c.transfers : 0

                        parts.push(
                            transfers === 0
                            ? qsTr("direct")
                            : qsTr("%1 change(s)").arg(transfers)
                        )

                        return parts.join("  ·  ")
                    }

                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        model: root.connections

        VerticalScrollDecorator {}
    }
}
