import QtQuick 2.0
import Sailfish.Silica 1.0

import Nemo.DBus 2.0
import MeeGo.Connman 0.2
import Sailfish.Bluetooth 1.0
import org.kde.bluezqt 1.0 as BluezQt

import com.jolla.settings.bluetooth.translations 1.0

Page {
    id: page

    allowedOrientations: Orientation.All

    readonly property QtObject _bluetoothManager: BluezQt.Manager
    property QtObject adapter: _bluetoothManager.usableAdapter
    readonly property bool bluetoothPoweredOn: btTechModel.available && btTechModel.powered && adapter && adapter.powered
    property QtObject _devicePendingPairing
    property var _connectingDevices: []
    readonly property bool empty: pairedDevices.count == 0 && nearbyDevices.count == 0
    readonly property bool discovering: adapter && adapter.discovering
    property var selectedDevice

    TechnologyModel {
        id: btTechModel
        name: "bluetooth"
    }

    function _connectToDevice(btDevice) {
        var pendingCall = btDevice.connectToDevice()
        pendingCall.userData = btDevice.address
        addConnectingDevice(btDevice.address)
        pendingCall.finished.connect(function(call) {
            removeConnectingDevice(call.userData)
            _deviceSelected()
        })
    }

    function _deviceSelected(address) {
        pageStack.push(Qt.resolvedUrl("SecondPage.qml"), {address: selectedDevice.Address, name: selectedDevice.FriendlyName})
    }

    function startDiscovery() {
        if (!discovering) {
            return
        }
        adapter.startDiscovery()
    }

    function stopDiscovery() {
        if (discovering) {
            adapter.stopDiscovery()
        }
    }

    function addConnectingDevice(addr) {
        addr = addr.toUpperCase()
        for (var i=0; i<_connectingDevices.length; i++) {
            if (_connectingDevices[i].toUpperCase() == addr) {
                return
            }
        }
        var devices = _connectingDevices
        devices.push(addr)
        _connectingDevices = devices
    }

    function removeConnectingDevice(addr) {
        addr = addr.toUpperCase()
        var devices = _connectingDevices
        for (var i=0; i<devices.length; i++) {
            if (devices[i].toUpperCase() == addr) {
                devices.splice(i, 1)
                _connectingDevices = devices
                return
            }
        }
    }

    function _deviceClicked(device) {
        _devicePendingPairing = null
        selectedDevice = device
//        selectedDevicePaired = paired
//        deviceClicked(address)

        if (!adapter || !adapter.powered) {
            return
        }
        console.log(device.Address)
        var deviceObj = _bluetoothManager.deviceForAddress(device.Address)
        if (!deviceObj) {
            return
        }
        if (device.Paired) {
            if (!deviceObj.connected) {
                _connectToDevice(deviceObj)
            } else {
                _deviceSelected()
            }
        }

        if (!device.Paired) {
            if (discovering) {
                stopDiscovery()
            }
            _devicePendingPairing = _bluetoothManager.deviceForAddress(device.Address)
            if (_devicePendingPairing) {
                pairingService.call("pairWithDevice", [device.Address])
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: column.height

        Column {
            id: column

            enabled: bluetoothPoweredOn

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Vasya")
            }

            BackgroundItem {
                id: bluetoothButton

                width: parent.width
                height: Theme.itemSizeMedium

                Rectangle {
                    anchors.fill: parent
                    color: "#80ff0000"
                    visible: !enabled
                }

                BusyIndicator {
                    anchors.centerIn: bluetoothIcon
                    size: BusyIndicatorSize.Medium
                    running: visible
                    visible: discovering
                }

                Image {
                    id: bluetoothIcon
                    source: "image://theme/icon-m-bluetooth" + (bluetoothButton.highlighted ? "?" + Theme.highlightColor : "")
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    anchors.left: bluetoothIcon.right
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter

                    text: enabled ? discovering ? qsTr("Stop searching") : qsTr("Search for devices")
                                  : qsTr("Please turn on bluetooth")
                    color: bluetoothButton.highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                onClicked: {
                    if (discovering) {
                        adapter.stopDiscovery()
                    } else {
                        adapter.startDiscovery()
                    }
                }
            }

            SectionHeader {
                id: pairedDevicesHeader

                //% "Paired devices"
                text: qsTrId("components_bluetooth-la-paired-devices")
            }

            ColumnView {
                id: pairedDevices

                width: parent.width
                itemHeight: Theme.itemSizeSmall

                model: BluezQt.DevicesModel {
                    id: knownDevicesModel
                    filters: BluezQt.DevicesModelPrivate.PairedDevices
                }

                delegate: ListItem {
                    id: pairedDelegate

                    property bool showConnectionStatus: model.Connected || isConnecting || minConnectionStatusTimeout.running
                    property bool isConnecting: _connectingDevices.indexOf(model.Address.toUpperCase()) >= 0

                    function _removePairing() {
                        var device = _bluetoothManager.deviceForAddress(model.Address)
                        if (device && adapter) {
                            adapter.removeDevice(device)
                        }
                    }

                    width: parent.width

                    onIsConnectingChanged: {
                        if (isConnecting) {
                            minConnectionStatusTimeout.start()
                        }
                    }

                    Timer {
                        id: minConnectionStatusTimeout
                        interval: 2000
                    }

                    menu: Component {
                        ContextMenu {
                            MenuItem {
                                //: Show settings for the selected bluetooth device
                                //% "Device settings"
                                text: qsTrId("components_bluetooth-me-device_settings")

                                onClicked: {
                                    var device = _bluetoothManager.deviceForAddress(model.Address)
                                    if (device) {
                                        pageStack.animatorPush(Qt.resolvedUrl("PairedDeviceSettings.qml"), {"bluetoothDevice": device})
                                    }
                                }
                            }

                            MenuItem {
                                //: Remove the pairing with the selected bluetooth device
                                //% "Remove pairing"
                                text: qsTrId("components_bluetooth-me-pairing_remove")

                                onClicked: {
                                    pairedDelegate._removePairing()
                                }
                            }
                        }
                    }

                    onClicked: {
                        _deviceClicked(model)
                    }

                    BluetoothDeviceInfo {
                        id: pairedDeviceInfo
                        address: model.Address
                        deviceClass: model.Class
                    }

                    Image {
                        id: icon
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/" + pairedDeviceInfo.icon + (pairedDelegate.highlighted ? "?" + Theme.highlightColor : "")
                    }

                    Label {
                        id: deviceNameLabel
                        anchors {
                            left: icon.right
                            leftMargin: Theme.paddingMedium
                            right: trustedIcon.left
                            rightMargin: Theme.paddingMedium
                        }
                        y: pairedDelegate.contentHeight/2 - implicitHeight/2
                           - (showConnectionStatus ? connectedLabel.implicitHeight/2 : 0)
                        text: model.FriendlyName
                        truncationMode: TruncationMode.Fade
                        color: pairedDelegate.highlighted
                               ? Theme.highlightColor
                               : Theme.primaryColor

                        Behavior on y { NumberAnimation {} }
                    }

                    Label {
                        id: connectedLabel
                        anchors {
                            left: deviceNameLabel.left
                            top: deviceNameLabel.bottom
                            right: parent.right
                            rightMargin: Theme.paddingLarge
                        }
                        font.pixelSize: Theme.fontSizeExtraSmall
                        opacity: showConnectionStatus ? 1.0 : 0.0
                        color: pairedDelegate.highlighted
                               ? Theme.secondaryHighlightColor
                               : Theme.secondaryColor

                        text: {
                            if (model.Connected) {
                                //% "Connected"
                                return qsTrId("components_bluetooth-la-connected")
                            } else if (pairedDelegate.isConnecting || minConnectionStatusTimeout.running) {
                                //% "Connecting"
                                return qsTrId("components_bluetooth-la-connecting")
                            } else {
                                return ""
                            }
                        }

                        Behavior on opacity { FadeAnimation {} }
                    }

                    Image {
                        id: trustedIcon
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin
                            verticalCenter: icon.verticalCenter
                        }
                        visible: model.Trusted
                        source: "image://theme/icon-s-certificates" + (pairedDelegate.highlighted ? "?" + Theme.highlightColor : "")
                        opacity: icon.opacity
                    }
                }
            }

            SectionHeader {
                //: List of bluetooth devices found nearby
                //% "Nearby devices"
                text: qsTrId("components_bluetooth-he-nearby_devices_header")
                visible: nearbyDevices.count > 0
            }

            ColumnView {
                id: nearbyDevices

                width: parent.width
                itemHeight: Theme.itemSizeSmall

                model: BluezQt.DevicesModel {
                    id: nearbyDevicesModel
                    filters: BluezQt.DevicesModelPrivate.UnpairedDevices
                }

                delegate: BackgroundItem {
                    id: nearbyDeviceDelegate

                    width: parent.width

                    BluetoothDeviceInfo {
                        id: nearbyDeviceInfo
                        address: model.Address
                        deviceClass: model.Class
                    }

                    Image {
                        id: nearbyDeviceIcon
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/" + nearbyDeviceInfo.icon + (nearbyDeviceDelegate.highlighted ? "?" + Theme.highlightColor : "")
                    }

                    Label {
                        anchors {
                            left: nearbyDeviceIcon.right
                            leftMargin: Theme.paddingMedium
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        text: model.FriendlyName
                        truncationMode: TruncationMode.Fade
                        color: nearbyDeviceDelegate.highlighted
                               ? Theme.highlightColor
                               : Theme.primaryColor
                    }

                    onClicked: {
                        _deviceClicked(model)
                    }
                }
            }

//            BluetoothDevicePicker {
//                id: devicePicker
//                width: parent.width
//                highlightSelectedDevice: false
//                requirePairing: true
//                showPairedDevicesHeader: true

//                onDeviceClicked: {
//                    if (!adapter || !adapter.powered || selectedDevice === "") {
//                        return
//                    }
//                    console.log(selectedDevice)
//                    var deviceObj = _bluetoothManager.deviceForAddress(selectedDevice)
//                    if (!deviceObj) {
//                        return
//                    }
//                    if (deviceObj.paired) {
//                        if (!deviceObj.connected) {
//                            page._connectToDevice(deviceObj)
//                        } else {
//                            _deviceSelected(deviceObj.address)
//                        }
//                    }
//                }

//                Timer {
//                    id: resetDeviceSelection
//                    interval: 100
//                    onTriggered: devicePicker.selectedDevice = ""
//                }
//            }
        }
    }

    Connections {
        target: _devicePendingPairing
        onPairedChanged: {
//            devicePaired(root._devicePendingPairing.address)
            _devicePendingPairing = null
        }
    }

    DBusInterface {
        id: pairingService
        service: "com.jolla.lipstick"
        path: "/bluetooth"
        iface: "com.jolla.lipstick"
    }
}
