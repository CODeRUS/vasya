#ifndef ELMCOMMUNICATOR_H
#define ELMCOMMUNICATOR_H

#include <QObject>
#include <QQmlParserStatus>
#include <QBluetoothSocket>
#include <QBluetoothServiceDiscoveryAgent>
#include <QBluetoothServiceInfo>

class ElmCommunicator : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
public:
    explicit ElmCommunicator(QObject *parent = nullptr);

    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    QString address() const;
    void setAddress(const QString &address);

    void componentComplete() override;
    void classBegin() override;

signals:
    void addressChanged(const QString &address);

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketError(QBluetoothSocket::SocketError error);
    void onSocketStateChanged(QBluetoothSocket::SocketState state);
    void onSocketReadyRead();

    void onServiceDiscovered(const QBluetoothServiceInfo &info);
    void onServiceDiscoveryFinished();

private:
    QString m_address;

    QBluetoothSocket *m_socket;
    QBluetoothServiceDiscoveryAgent *m_agent;
};

#endif // ELMCOMMUNICATOR_H
