#include <QApplication>
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
#include <QTimer>
#include <QSplashScreen>
#include <QPixmap>
#include <QScreen>
#include <QGuiApplication>
#include <QPainter>
#include <QIcon>
#include <QFileInfo>
#include <QCoreApplication>

#ifdef _WIN32
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <iostream>
#include <shlobj.h>
#include <objbase.h>
#endif

#include "FFmpegObject.h"
#include "timelinesync.h"

#include "splash.h"

#ifdef _WIN32
// 윈도우 파일 연결 등록 함수
bool registerFileAssociations() {
    QString appPath = QApplication::applicationFilePath().replace('/', '\\');
    QString appName = "Player by HEIMLICH";
    QString progId = "HEIMLICH.VideoPlayer";
    
    qDebug() << "Registering file associations for:" << appPath;
    
    // FFmpeg 지원 비디오/오디오 확장자들
    QStringList videoExtensions = {
        // 일반 비디오 포맷
        ".mp4", ".m4v", ".mkv", ".avi", ".mov", ".flv", ".webm", ".wmv",
        ".asf", ".rm", ".rmvb", ".mpg", ".mpeg", ".m2v", ".m4v", ".3gp",
        ".3g2", ".f4v", ".ogv", ".ts", ".mts", ".m2ts", ".vob", ".divx",
        ".dv", ".gxf", ".m1v", ".m2v", ".mxf", ".nsv", ".nuv", ".rec",
        ".viv", ".vivo", ".fli", ".flc", ".avi", ".vid", ".vdr",
        // DVD/Blu-ray
        ".ifo", ".vob", ".bdmv", ".mpls", ".m2ts", ".mts",
        // 특수 포맷
        ".y4m", ".yuv", ".ivf", ".h264", ".h265", ".hevc", ".264", ".265",
        ".raw", ".avs", ".avs2", ".vpy", ".vp8", ".vp9", ".av1",
        // 컨테이너
        ".nut", ".mxf", ".lavf", ".wtv", ".asf", ".stream",
        // 플레이리스트
        ".m3u", ".m3u8", ".pls", ".cue"
    };
    
    // ProgID 등록
    HKEY progIdKey;
    QString progIdPath = QString("SOFTWARE\\Classes\\%1").arg(progId);
    if (RegCreateKeyExA(HKEY_CURRENT_USER, progIdPath.toLocal8Bit().data(), 0, NULL, 
                        REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &progIdKey, NULL) == ERROR_SUCCESS) {
        
        // 기본값 설정 (앱 이름)
        RegSetValueExA(progIdKey, "", 0, REG_SZ, 
                      (BYTE*)appName.toLocal8Bit().data(), appName.length() + 1);
        
        // 아이콘 설정
        HKEY iconKey;
        if (RegCreateKeyExA(progIdKey, "DefaultIcon", 0, NULL, 
                           REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &iconKey, NULL) == ERROR_SUCCESS) {
            QString iconPath = QString("%1,0").arg(appPath);
            RegSetValueExA(iconKey, "", 0, REG_SZ, 
                          (BYTE*)iconPath.toLocal8Bit().data(), iconPath.length() + 1);
            RegCloseKey(iconKey);
        }
        
        // 열기 명령 설정
        HKEY commandKey;
        if (RegCreateKeyExA(progIdKey, "shell\\open\\command", 0, NULL, 
                           REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &commandKey, NULL) == ERROR_SUCCESS) {
            QString command = QString("\"%1\" \"%2\"").arg(appPath, "%1");
            RegSetValueExA(commandKey, "", 0, REG_SZ, 
                          (BYTE*)command.toLocal8Bit().data(), command.length() + 1);
            RegCloseKey(commandKey);
        }
        
        RegCloseKey(progIdKey);
    }
    
    // 각 확장자에 대해 등록
    for (const QString& ext : videoExtensions) {
        HKEY extKey;
        QString extPath = QString("SOFTWARE\\Classes\\%1").arg(ext);
        if (RegCreateKeyExA(HKEY_CURRENT_USER, extPath.toLocal8Bit().data(), 0, NULL, 
                           REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &extKey, NULL) == ERROR_SUCCESS) {
            
            // ProgID 연결
            RegSetValueExA(extKey, "", 0, REG_SZ, 
                          (BYTE*)progId.toLocal8Bit().data(), progId.length() + 1);
            
            // OpenWithProgids에 추가 (다른 앱들과 함께 나타나도록)
            HKEY openWithKey;
            if (RegCreateKeyExA(extKey, "OpenWithProgids", 0, NULL, 
                               REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &openWithKey, NULL) == ERROR_SUCCESS) {
                RegSetValueExA(openWithKey, progId.toLocal8Bit().data(), 0, REG_NONE, NULL, 0);
                RegCloseKey(openWithKey);
            }
            
            RegCloseKey(extKey);
        }
    }
    
    // 시스템에 변경사항 알림
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, NULL, NULL);
    
    qDebug() << "File associations registered successfully";
    return true;
}
#endif

// 버전 정보 가져오기 함수
QString getApplicationVersion() {
#ifdef VERSION_STRING
    return QString(VERSION_STRING);
#else
    // 빌드 시스템에서 버전 정보가 전달되지 않은 경우 기본값
    return QString("v%1.%2.%3")
           .arg(PROJECT_VERSION_MAJOR, 0)
           .arg(PROJECT_VERSION_MINOR, 0) 
           .arg(PROJECT_VERSION_PATCH, 0);
#endif
}

// 커스텀 스플래시 스크린 클래스 - 버전 정보 표시용
class CustomSplashScreen : public QSplashScreen {
    Q_OBJECT
    
private:
    QString versionText;
    QString loadingText;
    
public:
    CustomSplashScreen(const QPixmap &pixmap, Qt::WindowFlags f = Qt::WindowFlags()) 
        : QSplashScreen(pixmap, f), versionText(getApplicationVersion()), loadingText("Loading Player by HEIMLICH®...") {}
    
    void setVersionText(const QString &version) {
        versionText = version;
        repaint();
    }
    
    void setLoadingText(const QString &loading) {
        loadingText = loading;
        repaint();
    }
    
protected:
    void paintEvent(QPaintEvent *event) override {
        // 기본 이미지 그리기
        QSplashScreen::paintEvent(event);
        
        QPainter painter(this);
        painter.setRenderHint(QPainter::Antialiasing);
        
        // 로딩 텍스트 (하단 중앙)
        if (!loadingText.isEmpty()) {
            QFont loadingFont = painter.font();
            loadingFont.setPointSize(12);
            loadingFont.setBold(false);
            painter.setFont(loadingFont);
            painter.setPen(Qt::white);
            
            QRect loadingRect = rect();
            loadingRect.setHeight(loadingRect.height() - 40); // 버전 정보 공간 확보
            painter.drawText(loadingRect, Qt::AlignBottom | Qt::AlignHCenter, loadingText);
        }
        
        // 버전 텍스트 (메인 문구 아래 중앙)
        if (!versionText.isEmpty()) {
            QFont versionFont = painter.font();
            versionFont.setPointSize(8);  // 더 작은 글씨
            versionFont.setBold(false);
            painter.setFont(versionFont);
            painter.setPen(QColor(180, 180, 180)); // 더 연한 회색
            
            QRect versionRect = rect();
            versionRect.setHeight(versionRect.height() - 15); // 하단 여백
            painter.drawText(versionRect, Qt::AlignBottom | Qt::AlignHCenter, versionText);
        }
    }
};

// 스플래시 관리를 위한 더 안전한 클래스
class SplashManager : public QObject {
    Q_OBJECT
private:
    CustomSplashScreen* splash;
    
public:
    SplashManager(CustomSplashScreen* s, QObject* parent = nullptr) : QObject(parent), splash(s) {}
    
public slots:
    void closeSplash() {
        if (splash) {
            qDebug() << "=== MPV READY - CLOSING SPLASH ===";
            splash->setLoadingText("Player is Ready!");
            QTimer::singleShot(100, this, [this]() {
                if (splash) {
                    qDebug() << "=== QT SPLASH SCREEN CLOSING ===";
                    splash->close();
                    splash = nullptr;
                }
            });
        }
    }
};

// 전역 스플래시 매니저
static SplashManager* g_splashManager = nullptr;

// MPV에서 호출하는 안전한 스플래시 닫기 함수
void requestCloseSplash() {
    if (g_splashManager) {
        // 메인 스레드에서 안전하게 실행하도록 큐에 추가
        QMetaObject::invokeMethod(g_splashManager, "closeSplash", Qt::QueuedConnection);
    }
}

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
#ifdef _WIN32
    // Windows에서 콘솔 창 유지
    if (AllocConsole()) {
        freopen_s((FILE**)stdout, "CONOUT$", "w", stdout);
        freopen_s((FILE**)stderr, "CONOUT$", "w", stderr);
        freopen_s((FILE**)stdin, "CONIN$", "r", stdin);
        std::ios::sync_with_stdio(true);
        std::cout.clear();
        std::clog.clear();
        std::cerr.clear();
        std::cin.clear();
    }
#endif

    // 고해상도 디스플레이 지원 (DPI 스케일링)
    QApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    // Note: Qt::AA_EnableHighDpiScaling and Qt::AA_UseHighDpiPixmaps are deprecated in Qt 6
    // High-DPI scaling is automatically enabled in Qt 6

    QApplication app(argc, argv);
    
    // 명령줄 인수 처리 - 비디오 파일 경로 확인
    QString videoFilePath;
    QStringList args = QCoreApplication::arguments(); // argc/argv 변경 문제 방지
    
    qDebug() << "Application arguments count:" << args.size();
    qDebug() << "Command line arguments:" << args;
    
    // 첫 번째 인수는 실행 파일 경로이므로 두 번째부터 확인
    if (args.size() > 1) {
        // 파일 경로가 따옴표로 둘러싸여 있을 수 있으므로 제거
        QString potentialFile = args[1];
        if (potentialFile.startsWith('"') && potentialFile.endsWith('"')) {
            potentialFile = potentialFile.mid(1, potentialFile.length() - 2);
        }
        
        QFileInfo fileInfo(potentialFile);
        qDebug() << "Checking file:" << potentialFile;
        qDebug() << "File exists:" << fileInfo.exists();
        qDebug() << "Is file:" << fileInfo.isFile();
        
        // 파일이 존재하고 비디오 파일인지 확인
        if (fileInfo.exists() && fileInfo.isFile()) {
            // MPV가 지원하는 모든 비디오/오디오 확장자
            QStringList videoExtensions = {
                // 일반 비디오
                "mp4", "m4v", "mkv", "avi", "mov", "flv", "webm", "wmv",
                "asf", "rm", "rmvb", "mpg", "mpeg", "m2v", "3gp", "3g2",
                "f4v", "ogv", "ts", "mts", "m2ts", "vob", "divx", "xvid",
                "dv", "gxf", "m1v", "mxf", "nsv", "nuv", "rec", "viv",
                "vivo", "fli", "flc", "vid", "vdr",
                // 컨테이너
                "nut", "lavf", "wtv", "stream",
                // 오디오
                "mp3", "aac", "flac", "ogg", "wav", "wma", "m4a", "opus"
            };
            
            QString extension = fileInfo.suffix().toLower();
            qDebug() << "File extension:" << extension;
            
            if (videoExtensions.contains(extension)) {
                videoFilePath = fileInfo.absoluteFilePath();
                qDebug() << "Valid video file to open:" << videoFilePath;
            } else {
                qDebug() << "File is not a supported media format:" << extension;
            }
        } else {
            qDebug() << "File does not exist or is not a file:" << potentialFile;
        }
    } else {
        qDebug() << "No command line arguments provided (normal startup)";
    }
    
    // 애플리케이션 아이콘 설정 (실행파일 및 창 아이콘)
    QString iconPath;
    QDir currentDir(QDir::currentPath());
    
    // 플랫폼별 아이콘 파일 경로 찾기
    QStringList iconPaths;
    
#ifdef Q_OS_WIN
    // Windows: .ico 파일 우선
    iconPaths = {
        "assets/Images/icon_win.ico",
        "build/assets/Images/icon_win.ico", 
        "icon_win.ico",
        ":assets/Images/icon_win.ico",  // Qt 리소스 시스템
        // fallback to .icns if .ico not available
        "assets/Images/icon_mac.icns",
        ":assets/Images/icon_mac.icns"
    };
#elif defined(Q_OS_MAC)
    // macOS: .icns 파일 우선
    iconPaths = {
        "assets/Images/icon_mac.icns",
        "build/assets/Images/icon_mac.icns",
        "icon_mac.icns", 
        ":assets/Images/icon_mac.icns",  // Qt 리소스 시스템
        // fallback to .ico if .icns not available
        "assets/Images/icon_win.ico",
        ":assets/Images/icon_win.ico"
    };
#else
    // Linux 및 기타: 둘 다 시도
    iconPaths = {
        ":assets/Images/icon_win.ico",
        ":assets/Images/icon_mac.icns",
        "assets/Images/icon_win.ico",
        "assets/Images/icon_mac.icns"
    };
#endif
    
    QIcon appIcon;
    for (const QString& path : iconPaths) {
        if (QFile::exists(path)) {
            iconPath = path;
            appIcon = QIcon(path);
            qDebug() << "Found application icon at:" << path;
            break;
        }
    }
    
    // 리소스 시스템에서도 시도
    if (appIcon.isNull()) {
#ifdef Q_OS_WIN
        appIcon = QIcon(":assets/Images/icon_win.ico");
        qDebug() << "Using Windows icon from Qt resource system";
#elif defined(Q_OS_MAC)
        appIcon = QIcon(":assets/Images/icon_mac.icns");
        qDebug() << "Using macOS icon from Qt resource system";
#else
        appIcon = QIcon(":assets/Images/icon_win.ico");
        qDebug() << "Using icon from Qt resource system";
#endif
    }
    
    // 애플리케이션 아이콘 설정 (exe 파일 자체 아이콘)
    if (!appIcon.isNull()) {
        app.setWindowIcon(appIcon);
        qDebug() << "Application icon set successfully";
    } else {
        qDebug() << "Warning: Could not load application icon";
    }
    
    // Qt 스플래시 스크린 생성 및 표시
    QString imagePath;
    QPixmap splashPixmap;
    
    qDebug() << "Attempting to load splash image...";
    
    // 1. 먼저 Qt 리소스 시스템에서 시도 (가장 확실한 방법)
    splashPixmap = QPixmap(":assets/Images/HMLH-Player_IMG_splash.png");
    if (!splashPixmap.isNull()) {
        qDebug() << "Splash image loaded from Qt resources successfully. Size:" << splashPixmap.size();
    } else {
        qDebug() << "Qt resources loading failed, trying file system...";
        
        // 2. 애플리케이션 실행 파일이 있는 디렉토리에서 찾기 (설치된 환경)
        QString appDir = QCoreApplication::applicationDirPath();
        qDebug() << "Application directory for assets search:" << appDir;
        
        QStringList searchPaths = {
            appDir + "/assets/Images/HMLH-Player_IMG_splash.png",
            appDir + "/HMLH-Player_IMG_splash.png",
            appDir + "/../assets/Images/HMLH-Player_IMG_splash.png",
            // 3. 현재 작업 디렉토리에서 찾기 (개발 환경용 - 마지막에 시도)
            currentDir.absoluteFilePath("assets/Images/HMLH-Player_IMG_splash.png"),
            currentDir.absoluteFilePath("build/assets/Images/HMLH-Player_IMG_splash.png")
        };
        
        for (const QString& path : searchPaths) {
            qDebug() << "Trying splash image path:" << path;
            if (QFile::exists(path)) {
                splashPixmap = QPixmap(path);
                if (!splashPixmap.isNull()) {
                    qDebug() << "Splash image loaded from:" << path << "Size:" << splashPixmap.size();
                    imagePath = path;
                    break;
                } else {
                    qDebug() << "File exists but failed to load as pixmap:" << path;
                }
            } else {
                qDebug() << "File does not exist:" << path;
            }
        }
    }
    
    if (splashPixmap.isNull()) {
        qDebug() << "Failed to load splash image, creating default";
        
        // 더 안전한 기본 스플래시 생성
        splashPixmap = QPixmap(600, 400);
        splashPixmap.fill(QColor(30, 30, 35)); // 다크 배경
        
        // 간단한 텍스트만 추가 (QPainter 오류 방지)
        try {
            QPainter painter(&splashPixmap);
            if (painter.isActive()) {
                painter.setRenderHint(QPainter::Antialiasing);
                
                // 브랜드 텍스트
                QFont titleFont = painter.font();
                titleFont.setPointSize(28);
                titleFont.setBold(true);
                painter.setFont(titleFont);
                painter.setPen(Qt::white);
                painter.drawText(splashPixmap.rect(), Qt::AlignCenter, "HEIMLICH®\nPlayer");
                painter.end();
            }
        } catch (...) {
            qDebug() << "Warning: Could not draw text on splash screen";
        }
        
        qDebug() << "Default splash created with size:" << splashPixmap.size();
    } else {
        qDebug() << "Splash image loaded successfully. Size:" << splashPixmap.size();
        
        // 화면 크기 가져오기
        QScreen* screen = QGuiApplication::primaryScreen();
        QRect screenGeometry = screen->geometry();
        int screenWidth = screenGeometry.width();
        int screenHeight = screenGeometry.height();
        qreal devicePixelRatio = screen->devicePixelRatio();
        
        qDebug() << "Screen info - Size:" << screenWidth << "x" << screenHeight 
                 << "DPR:" << devicePixelRatio;
        
        // 스플래시 크기를 화면 크기의 35%로 조정 (고해상도 고려)
        int maxWidth = screenWidth * 0.35;   // 화면 너비의 35%
        int maxHeight = screenHeight * 0.5;  // 화면 높이의 50%
        
        // 고해상도 디스플레이에서는 더 큰 크기 허용
        if (devicePixelRatio > 1.0) {
            maxWidth = qMin(static_cast<int>(maxWidth * devicePixelRatio), static_cast<int>(screenWidth * 0.4));
            maxHeight = qMin(static_cast<int>(maxHeight * devicePixelRatio), static_cast<int>(screenHeight * 0.6));
        }
        
        // 이미지가 너무 크면 고품질 스케일링으로 축소
        if (splashPixmap.width() > maxWidth || splashPixmap.height() > maxHeight) {
            splashPixmap = splashPixmap.scaled(maxWidth, maxHeight, 
                                             Qt::KeepAspectRatio, 
                                             Qt::SmoothTransformation);
            qDebug() << "Splash image scaled to:" << splashPixmap.size();
        }
        
        // 고해상도 디스플레이를 위한 device pixel ratio 설정
        splashPixmap.setDevicePixelRatio(devicePixelRatio);
    }
    
    CustomSplashScreen splash(splashPixmap, Qt::WindowStaysOnTopHint);
    splash.setEnabled(false); // 사용자가 클릭으로 닫을 수 없게 설정
    splash.show();
    
    // 로딩 메시지와 버전 정보 설정
    splash.setLoadingText("Loading Player by HEIMLICH®...");
    splash.setVersionText(getApplicationVersion());
    
    qDebug() << "=== QT SPLASH SCREEN CREATED ===";
    
    app.processEvents(); // 스플래시가 즉시 그려지도록
    
    // 디버그 모드 활성화
    QLoggingCategory::setFilterRules("qt.qml.binding.removal.info=true");
    
    // 앱 정보 설정
    app.setApplicationName("Player by HEIMLICH®");
    app.setOrganizationName("HEIMLICH");
    app.setOrganizationDomain("heimlich.com");
    app.setApplicationVersion(getApplicationVersion());
    
    qDebug() << "Application starting..." << "Version:" << getApplicationVersion();
    
#ifdef QT_DEBUG
    // 디버그 모드에서 추가 로깅
    qDebug() << "Running in DEBUG mode";
#endif
    
    // QML 엔진 초기화
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    
    // FFmpeg 객체 등록 (QtQuick에서 사용 가능하도록)
    qmlRegisterType<FFmpegObject>("mpv", 1, 0, "MpvObject"); // MPV와 동일한 이름으로 등록하여 호환성 유지
    
    // TimelineSync 객체 생성 및 등록
    TimelineSync* timelineSync = new TimelineSync();
    qmlRegisterType<TimelineSync>("app.sync", 1, 0, "TimelineSync");
    
    // QML 모듈 등록 및 기본 속성 설정
    QQmlApplicationEngine engine;
    
    // QML 파일 경로 설정 - 애플리케이션 실행 파일 기준으로 설정
    QString qmlRootPath;
    QString appDir = QCoreApplication::applicationDirPath();
    
    qDebug() << "Application directory:" << appDir;
    qDebug() << "Current working directory:" << QDir::currentPath();
    
    // 1. 설치된 환경: 애플리케이션 실행 파일과 같은 디렉토리의 qml 폴더
    if (QDir(appDir + "/qml").exists() && QFile::exists(appDir + "/qml/core/MainWindow.qml")) {
        qmlRootPath = appDir + "/qml";
        qDebug() << "Using installed QML path (app dir):" << qmlRootPath;
    }
    // 2. 개발 환경: 프로젝트 디렉토리의 qml 폴더
    else if (currentDir.exists("qml/core/MainWindow.qml")) {
        qmlRootPath = currentDir.absoluteFilePath("qml");
        qDebug() << "Using development QML path (current dir):" << qmlRootPath;
    } 
    // 3. 빌드 환경: build/qml 폴더
    else if (currentDir.exists("build/qml/core/MainWindow.qml")) {
        qmlRootPath = currentDir.absoluteFilePath("build/qml");
        qDebug() << "Using build QML path:" << qmlRootPath;
    }
    // 4. 대체 경로: 애플리케이션 디렉토리 기준으로 한 번 더 시도
    else if (QDir(appDir + "/../qml").exists()) {
        qmlRootPath = QDir(appDir + "/../qml").absolutePath();
        qDebug() << "Using alternative QML path:" << qmlRootPath;
    }
    // 5. 최후 수단: 현재 디렉토리의 qml 폴더 (없어도 설정)
    else {
        qmlRootPath = currentDir.absoluteFilePath("qml");
        qDebug() << "Using fallback QML path:" << qmlRootPath;
    }
    
    qDebug() << "Final QML root path:" << qmlRootPath;
    
    // QML 파일이 실제로 존재하는지 확인
    QString mainWindowQml = qmlRootPath + "/core/MainWindow.qml";
    if (!QFile::exists(mainWindowQml)) {
        qDebug() << "ERROR: MainWindow.qml not found at:" << mainWindowQml;
        qDebug() << "Trying to find QML files in other locations...";
        
        // 추가 검색 경로들
        QStringList searchPaths = {
            appDir + "/qml/core/MainWindow.qml",
            appDir + "/../qml/core/MainWindow.qml", 
            currentDir.absoluteFilePath("qml/core/MainWindow.qml"),
            currentDir.absoluteFilePath("build/qml/core/MainWindow.qml")
        };
        
        for (const QString& path : searchPaths) {
            if (QFile::exists(path)) {
                qmlRootPath = QFileInfo(path).absolutePath();
                qmlRootPath.remove("/core"); // /core 부분 제거하여 루트 경로 얻기
                qDebug() << "Found QML files at:" << qmlRootPath;
                break;
            }
        }
    }
    
    // Import 경로 추가 - 애플리케이션 디렉토리 기준
    engine.addImportPath(qmlRootPath);
    engine.addImportPath(appDir + "/qml");  // 추가 안전장치
    
    // 작업 디렉토리를 QML 디렉토리로 변경하지 않음 (영상 파일 경로 문제 방지)
    // QDir::setCurrent(qmlRootPath); // 이 줄 제거!
    qDebug() << "Working directory preserved as:" << QDir::currentPath();
    
    engine.rootContext()->setContextProperty("hasMpvSupport", true);
    engine.rootContext()->setContextProperty("timelineSync", timelineSync);
    
    // 애플리케이션 정보를 QML에 전달
    engine.rootContext()->setContextProperty("appName", "Player by HEIMLICH®");
    engine.rootContext()->setContextProperty("appVersion", getApplicationVersion());
    engine.rootContext()->setContextProperty("appCompany", "HEIMLICH");
    engine.rootContext()->setContextProperty("appDescription", "Professional Video Player");
    engine.rootContext()->setContextProperty("appCopyright", "© 2025 HEIMLICH. All rights reserved.");
    
    // 명령줄에서 전달받은 비디오 파일 경로를 QML에 전달
    engine.rootContext()->setContextProperty("initialVideoFile", videoFilePath);
    qDebug() << "Initial video file passed to QML:" << videoFilePath;
    
    // 부트스트랩 QML 파일 로드 - 메인 윈도우를 직접 로드
    QString mainQmlFile = qmlRootPath + "/core/MainWindow.qml";
    qDebug() << "Loading Main Window from:" << mainQmlFile;
    
    // 메인 윈도우 로드
    engine.load(QUrl::fromLocalFile(mainQmlFile));
    
    if (engine.rootObjects().isEmpty()) {
        qDebug() << "Failed to load Main Window:" << mainQmlFile;
        if (g_splashManager) {
            g_splashManager->closeSplash();
            g_splashManager = nullptr;
        }
        return -1;
    }
    
    // 전역 스플래시 매니저 설정
    g_splashManager = new SplashManager(&splash);
    
#ifdef _WIN32
    // 윈도우에서 파일 연결 등록 (처음 실행 시 또는 필요 시)
    try {
        registerFileAssociations();
    } catch (...) {
        qDebug() << "Warning: Failed to register file associations";
    }
#endif
    
    return app.exec();
}

#include "main.moc" 