#ifndef MPVOBJECT_H
#define MPVOBJECT_H

#include <QtQuick/QQuickFramebufferObject>
#include <client.h>
#include <render_gl.h>
#include <QTimer>
#include <QVariant>
#include <QDateTime>

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(QString filename READ filename NOTIFY filenameChanged)
    Q_PROPERTY(bool pause READ isPaused NOTIFY pauseChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY mediaTitleChanged)
    Q_PROPERTY(double fps READ fps NOTIFY fpsChanged)
    Q_PROPERTY(bool endReached READ isEndReached NOTIFY endReachedChanged)
    Q_PROPERTY(bool loop READ isLoopEnabled WRITE setLoopEnabled NOTIFY loopChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY frameCountChanged)
    Q_PROPERTY(bool oneBasedFrameNumbers READ isOneBasedFrameNumbers WRITE setOneBasedFrameNumbers NOTIFY oneBasedFrameNumbersChanged)

    mpv_handle *mpv;
    mpv_render_context *mpv_context;
    friend class MpvRenderer;

    QString m_filename;
    QString m_mediaTitle;
    bool m_pause = false;
    double m_position = 0;
    double m_duration = 0;
    double m_lastPosition = 0;
    double m_fps = 0.0;
    bool m_pendingPauseState = false;
    bool m_endReached = false;
    bool m_loopEnabled = false;
    int m_frameCount = 0;
    bool m_oneBasedFrameNumbers = false; // 기본값은 0-기반
    
    // 성능 모니터링 관련 변수
    QDateTime m_lastPerformanceCheck;
    bool m_performanceOptimizationApplied = false;
    
    // 시크 관련 변수
    qint64 m_lastSeekTime = 0;
    
    // 타이머
    QTimer *m_stateChangeTimer = nullptr;
    QTimer *m_performanceTimer = nullptr;

public:
    explicit MpvObject(QQuickItem * parent = 0);
    virtual ~MpvObject();
    virtual Renderer *createRenderer() const;

    QString filename() const;
    bool isPaused() const;
    double position() const;
    double duration() const;
    double fps() const;
    QString mediaTitle() const;
    bool isEndReached() const;
    bool isLoopEnabled() const;
    void setLoopEnabled(bool enabled);
    int frameCount() const;
    bool isOneBasedFrameNumbers() const;
    void setOneBasedFrameNumbers(bool oneBased);

public slots:
    void play();
    void pause();
    void playPause();
    void command(const QVariant& params);
    void setProperty(const QString& name, const QVariant& value);
    QVariant getProperty(const QString& name);
    void handleMpvEvents();
    void updatePositionProperty();
    void processStateChange();
    void checkPerformance();
    void resetEndReached();
    void handleEndOfVideo();
    void seekToPosition(double pos);
    void updateFrameCount();
    void applyVideoFilters(const QStringList& filters);
    void frameStep(int frames);

signals:
    void pauseChanged(bool);
    void playingChanged(bool);
    void positionChanged(double);
    void durationChanged(double);
    void mediaTitleChanged(const QString&);
    void filenameChanged(const QString&);
    void videoReconfig();
    void seekRequested(int frame);
    void fpsChanged(double);
    void endReachedChanged(bool);
    void loopChanged(bool);
    void frameCountChanged(int);
    void oneBasedFrameNumbersChanged(bool);
};

#endif // MPVOBJECT_H 