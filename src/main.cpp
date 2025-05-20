#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QDebug>
#include <QQuickWindow>
#include <QLoggingCategory>
#include <QFile>
#include <QDateTime>
#include <QStandardPaths>
#include <QSGRendererInterface>
#include <QQmlEngine>

#ifdef HAVE_MPV
#include "mpvobject.h"
#include "timelinesync.h"
#endif

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
    QGuiApplication app(argc, argv);
    
    // 디버그 모드 활성화
    QLoggingCategory::setFilterRules("qt.qml.binding.removal.info=true");
    
    // 앱 정보 설정
    app.setApplicationName("HYPER-PLAYER");
    app.setOrganizationName("HyperMedia");
    app.setOrganizationDomain("hypermedia.example");
    
    qDebug() << "Application starting...";
    
#ifdef QT_DEBUG
    // 디버그 모드에서 추가 로깅
    qDebug() << "Running in DEBUG mode";
#endif
    
    // QML 엔진 초기화
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    
#ifdef HAVE_MPV
    // MPV 객체 등록 (QtQuick에서 사용 가능하도록)
    qmlRegisterType<MpvObject>("mpv", 1, 0, "MpvObject");
    
    // TimelineSync 객체 생성 및 등록
    TimelineSync* timelineSync = new TimelineSync();
    qmlRegisterType<TimelineSync>("app.sync", 1, 0, "TimelineSync");
#endif
    
    // QML 모듈 등록 및 기본 속성 설정
    QQmlApplicationEngine engine;
    
    // QML 파일 경로 설정
    QString qmlRootPath;
    QDir appDir(QDir::currentPath());
    
    // 개발 환경에서는 프로젝트 디렉토리의 qml 폴더 사용
    if (appDir.exists("qml/core/MainWindow.qml")) {
        qmlRootPath = appDir.absoluteFilePath("qml");
    } 
    // 빌드 환경에서는 build/qml 폴더 사용
    else if (appDir.exists("build/qml/core/MainWindow.qml")) {
        qmlRootPath = appDir.absoluteFilePath("build/qml");
    }
    // 배포 환경에서는 실행 파일과 같은 위치의 qml 폴더 사용
    else {
        qmlRootPath = appDir.absoluteFilePath("qml");
    }
    
    qDebug() << "QML root path:" << qmlRootPath;
    
    // Import 경로 추가
    engine.addImportPath(qmlRootPath);
    
    // 중요: 이 경로를 먼저 지정해야 QML 모듈이 제대로 로드됨
    QDir::setCurrent(qmlRootPath);
    qDebug() << "Current directory set to:" << QDir::currentPath();
    
#ifdef HAVE_MPV
    engine.rootContext()->setContextProperty("hasMpvSupport", true);
    engine.rootContext()->setContextProperty("timelineSync", timelineSync);
#else
    engine.rootContext()->setContextProperty("hasMpvSupport", false);
#endif
    
    // 부트스트랩 QML 파일 로드
    QString mainQmlFile = qmlRootPath + "/core/MainWindow.qml";
    qDebug() << "Loading QML file from:" << mainQmlFile;
    
    // QML 파일 로드
    engine.load(QUrl::fromLocalFile(mainQmlFile));
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML file:" << mainQmlFile;
        return -1;
    }
    
    return app.exec();
} 