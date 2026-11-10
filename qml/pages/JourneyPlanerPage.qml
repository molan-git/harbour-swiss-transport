import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Journey planner"
                description: "Find a public transport connection"
            }

            TextField {
                id: fromField

                width: parent.width
                label: "Departure"
                placeholderText: "e.g. Basel SBB"

                EnterKey.enabled: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
            }

            TextField {
                id: toField

                width: parent.width
                label: "Destination"
                placeholderText: "e.g. Zürich HB"

                EnterKey.enabled: true
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"

                EnterKey.onClicked: {
                    findConnections()
                    focus = false
                }
            }

            Button {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Find connections"

                onClicked: {
                    findConnections()
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
                text: "Connections"
            }

            Repeater {
                model: transportClient.connectionModel

                delegate: ListItem {
                    width: column.width
                    contentHeight: Theme.itemSizeExtraLarge

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }

                        spacing: Theme.paddingSmall

                        Label {
                            width: parent.width
                            text: model.identifier
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeMedium
                        }

                        Label {
                            width: parent.width
                            text: model.title + " → " + model.subtitle
                            color: Theme.highlightColor
                        }

                        Label {
                            width: parent.width
                            text: "Duration: " + model.time
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            width: parent.width
                            text: "Services: " + model.platform
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Label {
                visible: transportClient.connectionModel.count === 0
                         && !transportClient.busy
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: "Enter a departure and destination."
            }
        }
    }

    function findConnections() {
        transportClient.searchConnections(
            fromField.text,
            toField.text
        )
    }
}
