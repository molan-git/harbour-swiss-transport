import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: "Plan a journey"
                onClicked: pageStack.push(
                    Qt.resolvedUrl("JourneyPlanerPage.qml")
                )
            }
        }

        VerticalScrollDecorator {}

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Find a station"
            }

            TextField {
                id: searchField

                width: parent.width
                placeholderText: "e.g. Basel SBB"
                label: "Station or stop"

                EnterKey.enabled: true
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"

                EnterKey.onClicked: {
                    transportClient.searchStations(text)
                    focus = false
                }
            }

            Button {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Search"

                onClicked: {
                    transportClient.searchStations(searchField.text)
                }
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

            SectionHeader {
                text: "Search results"
            }

            Repeater {
                model: transportClient.stationModel

                delegate: ListItem {
                    width: column.width
                    contentHeight: Theme.itemSizeMedium

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }

                        Label {
                            width: parent.width
                            text: model.title
                            color: Theme.primaryColor
                            truncationMode: TruncationMode.Fade
                        }

                        Label {
                            width: parent.width
                            text: model.subtitle
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }

                    onClicked: {
                        pageStack.push(
                            Qt.resolvedUrl("StationBoardPage.qml"),
                            {
                                stationId: model.identifier,
                                stationName: model.title
                            }
                        )
                    }
                }
            }

            Label {
                visible: transportClient.stationModel.count === 0
                         && !transportClient.busy

                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: "Search for a station to see results."
            }
        }
    }
}
