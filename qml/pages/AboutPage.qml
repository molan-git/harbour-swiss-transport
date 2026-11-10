import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("About") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.primaryColor
                text: qsTr("Swiss Transport")
                font.pixelSize: Theme.fontSizeLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                text: qsTr("Version 0.2.0") + "\n\n" +
                      qsTr("Timetables, departures and real-time delays for Swiss " +
                           "public transport (SBB and all partner operators).")
            }

            SectionHeader { text: qsTr("Data source") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("This app uses the free transport.opendata.ch API, " +
                           "based on the official Swiss public transport open data " +
                           "(OJP / GTFS-RT). Real-time information where available.")
            }
        }

        VerticalScrollDecorator {}
    }
}
