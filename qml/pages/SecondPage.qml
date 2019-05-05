import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.vasya 1.0

Page {
    id: page

    property alias address: elm.address
    property alias name: pageHeader.title

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        console.log(address)
    }

    ElmCommunicator {
        id: elm
    }

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                id: pageHeader
            }
        }
    }
}
