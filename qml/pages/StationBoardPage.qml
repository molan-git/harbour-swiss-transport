import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property string stationId: ""
    property string stationName: ""

    Component.onCompleted: {
        refreshBoard()
    }

    function refreshBoard() {
        transportClient.loadDepartures(stationId, stationName)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: "Refresh departures"
                onClicked: page.refreshBoard()
            }
        }

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: stationName
                description: "Departures"
            }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: transportClient.busy
                visible: running
            }

            Label {
                visible: transportClient.errorMessage.length > 0
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.errorColor
                text: transportClient.errorMessage
            }

            Repeater {
                model: transportClient.departureModel

                delegate: ListItem {
                    width: column.width
                    contentHeight: Theme.itemSizeLarge

                    Row {
                        anchors {
                            fill: parent
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }

                        spacing: Theme.paddingMedium

                        Label {
                            width: Theme.itemSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.time
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeLarge
                        }

                        Column {
                            width: parent.width - Theme.itemSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.paddingSmall

                            Label {
                                width: parent.width
                                text: model.title
                                color: Theme.primaryColor
                                font.pixelSize: Theme.fontSizeMedium
                            }

                            Label {
                                width: parent.width
                                text: model.subtitle
                                color: Theme.secondaryColor
                                truncationMode: TruncationMode.Fade
                            }

                            Label {
                                width: parent.width
                                text: model.platform
                                      ? "Platform " + model.platform
                                      : "Platform unavailable"
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }

                            Label {
                                width: parent.width
                                visible: model.delay !== ""
                                text: "Delay: " + model.delay + " min"
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }
                        }
                    }
                }
            }

            Label {
                visible: transportClient.departureModel.count === 0
                         && !transportClient.busy
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: "No departures available."
            }

            Button {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Refresh"
                onClicked: page.refreshBoard()
            }
        }
    }
}
