# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If TARGET is changed, the following names must also be updated:
#   - Main QML filename
#   - Desktop icon filename
#   - Desktop filename
#   - Icon definition in desktop file
#   - Translation filenames

# Application name
TARGET = harbour-swiss-transport


# Sailfish application configuration
CONFIG += sailfishapp


# Qt modules
# Qt Network is required for transport.opendata.ch API requests.
QT += network


# Application source files
SOURCES += \
    src/main.cpp \
    src/appsettings.cpp


# Header files
HEADERS += \
    src/appsettings.h


# QML pages, cover and application distribution files
DISTFILES += \
    qml/harbour-swiss-transport.qml \
    qml/cover/CoverPage.qml \
    qml/js/Api.js \
    qml/pages/MainPage.qml \
    qml/pages/StationPickerPage.qml \
    qml/pages/ConnectionsPage.qml \
    qml/pages/ConnectionDetailPage.qml \
    qml/pages/StationboardPage.qml \
    qml/pages/FavouritesPage.qml \
    qml/pages/NearbyPage.qml \
    qml/pages/AboutPage.qml \
    rpm/harbour-swiss-transport.changes.in \
    rpm/harbour-swiss-transport.changes.run.in \
    rpm/harbour-swiss-transport.spec \
    translations/harbour-swiss-transport-de.ts \
    translations/harbour-swiss-transport.ts \
    harbour-swiss-transport.desktop


# Application icons
SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172


# Internationalization
# Comment out this CONFIG line to disable automatic translation building.
CONFIG += sailfishapp_i18n


# Translations
TRANSLATIONS += \
    translations/harbour-swiss-transport-de.ts
