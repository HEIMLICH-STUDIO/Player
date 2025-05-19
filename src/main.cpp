#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QQmlFileSelector>
#include <QQuickWindow>
#include <QLoggingCategory>
#include <QFile>
#include <QDateTime>
#include <QStandardPaths>
#include <QSGRendererInterface>

#include "mpvobject.h"

// 메시지 핸들러 함수
void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    // Open log file
    QString logPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/hyper-player-log.txt";
    QFile logFile(logPath);
    if (logFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
        
        // Format message
        QString txt;
        switch (type) {
        case QtDebugMsg:
            txt = QString("Debug: %1").arg(msg);
            break;
        case QtInfoMsg:
            txt = QString("Info: %1").arg(msg);
            break;
        case QtWarningMsg:
            txt = QString("Warning: %1").arg(msg);
            break;
        case QtCriticalMsg:
            txt = QString("Critical: %1").arg(msg);
            break;
        case QtFatalMsg:
            txt = QString("Fatal: %1").arg(msg);
            break;
        }
        
        // Add timestamp and write to file
        QTextStream out(&logFile);
        out << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz ") << txt << " (" << context.file << ":" << context.line << ", " << context.function << ")" << Qt::endl;
        
        // Also output to console
        fprintf(stderr, "%s\n", qPrintable(txt));
    }
}

int main(int argc, char *argv[])
{
    // 로그 핸들러 설정
    qInstallMessageHandler(messageHandler);
    qDebug() << "Application starting...";
    
    // Qt OpenGL 설정을 명시적으로 지정
    QGuiApplication::setAttribute(Qt::AA_UseDesktopOpenGL);
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    
    // 디버그 플래그 활성화
    qputenv("QSG_INFO", "1");
    qputenv("QSG_RENDER_TIMING", "1");
    qputenv("QT_LOGGING_RULES", "qt.scenegraph.*=true");
    
    QGuiApplication app(argc, argv);
    
    // MPV 모듈 등록
    qmlRegisterType<MpvObject>("mpv", 1, 0, "MpvObject");
    
    // QML 모듈 등록 및 기본 속성 설정
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("hasMpvSupport", true);
    
    // QML 파일 로드
    QString qmlFilePath = QDir::currentPath() + "/qml/main.qml";
    qDebug() << "Loading QML from filesystem path:" << qmlFilePath;
    
    engine.load(QUrl::fromLocalFile(qmlFilePath));
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML file:" << qmlFilePath;
        return -1;
    }
    
    qDebug() << "Successfully created QML object from" << qmlFilePath;
    
    // 이벤트 루프 시작
    qDebug() << "Starting event loop";
    return app.exec();
} 