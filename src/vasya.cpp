#include <QtQuick>
#include <sailfishapp.h>
#include "elmcommunicator.h"

int main(int argc, char *argv[])
{
    qmlRegisterType<ElmCommunicator>("org.coderus.vasya", 1, 0, "ElmCommunicator");

    return SailfishApp::main(argc, argv);
}
