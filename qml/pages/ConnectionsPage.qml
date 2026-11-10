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

    function fromKey() { return fromStation.id ? fromStation.id : fromStation.name }
    function toKey()   { return toStation.id ? toStation.id : toStation.name }

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
                onClicked: { root.page += 1; root.reload() }
            }
            MenuItem {
                text: qsTr("Earlier connections")
                enabled: root.page > 0
                onClicked: { root.page -= 1; root.reload() }
            }
        }

        header: Column {
            width: parent.width
            PageHeader {
                title: qsTr("Connections")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: root.fromStation.name + " → " + root.toStation.name
                      + "\n" + root.dateStr + "  " + root.timeStr
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: root.loading
            visible: running
            size: BusyIndicatorSize.Large
        }

        ViewPlaceholder {
            enabled: !root.loading && root.connections.length === 0 && root.errorText === ""
            text: qsTr("No connections found")
        }

        ViewPlaceholder {
            enabled: root.errorText !== ""
            text: qsTr("Request failed")
            hintText: root.errorText
        }

        delegate: BackgroundItem {
            id: item
            property var c: modelData

            onClicked: pageStack.push(Qt.resolvedUrl("ConnectionDetailPage.qml"),
                                      { connection: c })

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall

                Row {
                    spacing: Theme.paddingSmall
                    Label {
                        text: Api.hhmm(c.from.departure)
                        color: c.from.delay && c.from.delay > 0 ? "red" : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }
                    Label {
                        text: "→"
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }
                    Label {
                        text: Api.hhmm(c.to.arrival)
                        color: c.to.delay && c.to.delay > 0 ? "red" : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }

                Label {
                    width: parent.width
                    text: {
                        var parts = []
                        if (c.from.delay && c.from.delay > 0)
                            parts.push(qsTr("Departs %1 min late").arg(c.from.delay))
                        var transfers = 0
                        var products = []
                        if (c.sections) {
                            for (var i = 0; i < c.sections.length; i++) {
                                var s = c.sections[i]
                                if (s.journey) {
                                    transfers++
                                    var l = Api.lineLabel(s)
                                    if (products.indexOf(l) < 0) products.push(l)
                                }
                            }
                            transfers = Math.max(0, transfers - 1)
                        }
                        if (products.length) parts.push(products.join(" · "))
                        parts.push(transfers === 0 ? qsTr("direct")
                                                    : qsTr("%1 change(s)").arg(transfers))
                        parts.push(Api.fmtDuration(c.duration / 60))
                        return parts.join(" · ")
                    }
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                }
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: Api.fmtDuration(c.duration / 60)
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        model: connections
        VerticalScrollDecorator {}
    }
}
