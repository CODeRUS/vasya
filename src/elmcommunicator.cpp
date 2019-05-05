#include "elmcommunicator.h"

#include <QBluetoothAddress>

#include <QDebug>

ElmCommunicator::ElmCommunicator(QObject *parent)
    : QObject(parent)
    , m_socket(new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol, this))
    , m_agent(new QBluetoothServiceDiscoveryAgent(this))
{
    connect(m_socket, &QBluetoothSocket::connected, this, &ElmCommunicator::onSocketConnected);
    connect(m_socket, &QBluetoothSocket::disconnected, this, &ElmCommunicator::onSocketDisconnected);
//    connect(m_socket, &QBluetoothSocket::error, this, &ElmCommunicator::onSocketError);
    connect(m_socket, static_cast<void (QBluetoothSocket::*)(QBluetoothSocket::SocketError)>(&QBluetoothSocket::error), this, &ElmCommunicator::onSocketError);
    connect(m_socket, &QBluetoothSocket::stateChanged, this, &ElmCommunicator::onSocketStateChanged);
    connect(m_socket, &QBluetoothSocket::readyRead, this, &ElmCommunicator::onSocketReadyRead);

    connect(m_agent, &QBluetoothServiceDiscoveryAgent::serviceDiscovered, this, &ElmCommunicator::onServiceDiscovered);
    connect(m_agent, &QBluetoothServiceDiscoveryAgent::finished, this, &ElmCommunicator::onServiceDiscoveryFinished);
}

QString ElmCommunicator::address() const
{
    return m_address;
}

void ElmCommunicator::setAddress(const QString &address)
{
    if (m_address == address) {
        return;
    }

    m_address = address;
    emit addressChanged(m_address);
}

void ElmCommunicator::componentComplete()
{
    qDebug() << Q_FUNC_INFO << m_address;
    m_agent->setRemoteAddress(QBluetoothAddress(m_address));
    m_agent->start(QBluetoothServiceDiscoveryAgent::FullDiscovery);
}

void ElmCommunicator::classBegin()
{
    qDebug() << Q_FUNC_INFO;
}

void ElmCommunicator::onSocketConnected()
{
    qDebug() << Q_FUNC_INFO;
}

void ElmCommunicator::onSocketDisconnected()
{
    qDebug() << Q_FUNC_INFO;
}

void ElmCommunicator::onSocketError(QBluetoothSocket::SocketError error)
{
    qDebug() << Q_FUNC_INFO << error << m_socket->errorString();
}

void ElmCommunicator::onSocketStateChanged(QBluetoothSocket::SocketState state)
{
    qDebug() << Q_FUNC_INFO << state;
}

void ElmCommunicator::onSocketReadyRead()
{
    qDebug() << Q_FUNC_INFO;
    qDebug().noquote() << m_socket->readAll();
}

void ElmCommunicator::onServiceDiscovered(const QBluetoothServiceInfo &info)
{
    qDebug() << Q_FUNC_INFO << info.serviceName() << info.serverChannel() << info.socketProtocol();

    if (info.socketProtocol() == QBluetoothServiceInfo::RfcommProtocol
            && (info.serviceName().contains(QLatin1String("SPP"))
                || info.serviceName().contains(QLatin1String("Port")))) {
        qDebug() << Q_FUNC_INFO << "Connecting" << info.serviceName() << info.serverChannel() << info.socketProtocol();

        m_agent->stop();
        m_socket->connectToService(info);
    }
}

void ElmCommunicator::onServiceDiscoveryFinished()
{
    qDebug() << Q_FUNC_INFO;
}
