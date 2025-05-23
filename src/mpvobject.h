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
    
    // 비디오 코덱 정보를 위한 새 프로퍼티
    Q_PROPERTY(QString videoCodec READ videoCodec NOTIFY videoCodecChanged)
    Q_PROPERTY(QString videoFormat READ videoFormat NOTIFY videoFormatChanged)
    Q_PROPERTY(QString videoResolution READ videoResolution NOTIFY videoResolutionChanged)
    
    // 타임코드 관련 프로퍼티 추가
    Q_PROPERTY(QString timecode READ timecode NOTIFY timecodeChanged)
    Q_PROPERTY(int timecodeFormat READ timecodeFormat WRITE setTimecodeFormat NOTIFY timecodeFormatChanged)
    Q_PROPERTY(bool useEmbeddedTimecode READ useEmbeddedTimecode WRITE setUseEmbeddedTimecode NOTIFY useEmbeddedTimecodeChanged)
    Q_PROPERTY(QString embeddedTimecode READ embeddedTimecode NOTIFY embeddedTimecodeChanged)
    Q_PROPERTY(int timecodeOffset READ timecodeOffset WRITE setTimecodeOffset NOTIFY timecodeOffsetChanged)
    Q_PROPERTY(QString customTimecodePattern READ customTimecodePattern WRITE setCustomTimecodePattern NOTIFY customTimecodePatternChanged)
    Q_PROPERTY(int timecodeSource READ timecodeSource WRITE setTimecodeSource NOTIFY timecodeSourceChanged)

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
    
    // 코덱 정보 변수 추가
    QString m_videoCodec = "";
    QString m_videoFormat = "";
    QString m_videoResolution = "";
    
    // 타임코드 관련 변수
    QString m_timecode = "00:00:00:00";
    int m_timecodeFormat = 0; // 0=SMPTE Non-Drop, 1=SMPTE Drop-Frame, 2=HH:MM:SS.MS, 3=Frames Only
    bool m_useEmbeddedTimecode = false;
    QString m_embeddedTimecode = "";
    int m_timecodeOffset = 0;
    QString m_customTimecodePattern = "%H:%M:%S.%f";
    int m_timecodeSource = 0; // 0=Calculate, 1=Embedded SMPTE, 2=File Metadata, 3=Reel Name
    
    // 성능 모니터링 관련 변수
    QDateTime m_lastPerformanceCheck;
    bool m_performanceOptimizationApplied = false;
    
    // 시크 관련 변수
    qint64 m_lastSeekTime = 0;
    
    // 타이머
    QTimer *m_stateChangeTimer = nullptr;
    QTimer *m_performanceTimer = nullptr;
    QTimer *m_metadataTimer = nullptr;  // 메타데이터 업데이트 타이머
    QTimer *m_timecodeTimer = nullptr;  // 타임코드 업데이트 타이머

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
    
    // 코덱 정보 접근자 추가
    QString videoCodec() const;
    QString videoFormat() const;
    QString videoResolution() const;
    
    // 타임코드 관련 접근자/설정자
    QString timecode() const;
    int timecodeFormat() const;
    void setTimecodeFormat(int format);
    bool useEmbeddedTimecode() const;
    void setUseEmbeddedTimecode(bool use);
    QString embeddedTimecode() const;
    int timecodeOffset() const;
    void setTimecodeOffset(int offset);
    QString customTimecodePattern() const;
    void setCustomTimecodePattern(const QString& pattern);
    int timecodeSource() const;
    void setTimecodeSource(int source);
    
    // 타임코드 유틸리티 메서드
    Q_INVOKABLE QString frameToTimecode(int frame, int format = -1, const QString& customPattern = "") const;
    Q_INVOKABLE int timecodeToFrame(const QString& tc) const;

    // 프레임 번호 변환 함수 추가
    int displayFrameNumber(int internalFrame) const;
    int internalFrameNumber(int displayFrame) const;

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
    void updateVideoMetadata();  // 메타데이터 업데이트 함수 추가
    void applyVideoFilters(const QStringList& filters);
    void updateTimecode();      // 타임코드 업데이트 함수
    void fetchEmbeddedTimecode(); // 내장 타임코드 추출 함수

signals:
    void positionChanged(double position);
    void durationChanged(double duration);
    void fpsChanged(double fps);
    void mediaTitleChanged(const QString &mediaTitle);
    void filenameChanged(const QString &filename);
    void pauseChanged(bool paused);
    void playingChanged(bool playing);
    void frameCountChanged(int count);
    void videoReconfig();
    void fileLoaded();
    void seekRequested(int frame);
    void videoCodecChanged(const QString &codec);
    void videoFormatChanged(const QString &format);
    void videoResolutionChanged(const QString &resolution);
    void videoMetadataChanged();
    void timecodeChanged(const QString &timecode);
    void timecodeFormatChanged(int format);
    void useEmbeddedTimecodeChanged(bool use);
    void embeddedTimecodeChanged(const QString &timecode);
    void timecodeOffsetChanged(int offset);
    void customTimecodePatternChanged(const QString &pattern);
    void timecodeSourceChanged(int source);
    void loopChanged(bool enabled);
    void oneBasedFrameNumbersChanged(bool oneBased);
    void endReached();  // 영상 종료 시 발생하는 시그널
    void endReachedChanged(bool reached);  // endReached 속성 변경 시그널
};

#endif // MPVOBJECT_H 