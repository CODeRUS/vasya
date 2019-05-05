TARGET = vasya

QT += bluetooth
CONFIG += sailfishapp

SOURCES += \
    src/vasya.cpp \
    src/elmcommunicator.cpp

HEADERS += \
    src/elmcommunicator.h

DISTFILES += \
    qml/vasya.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/SecondPage.qml \
    rpm/vasya.spec \
    translations/*.ts \
    vasya.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/vasya-ru.ts
