#ifndef FFMPEGOBJECT_H
#define FFMPEGOBJECT_H

#include <QObject>
#include <QQuickItem>
#include <QQuickWindow>
#include <QOpenGLFunctions>
#include <QTimer>
#include <QMutex>
#include <QThread>
#include <QVariant>
#include <QString>
#include <QVariantList>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
}

class FFmpegRenderer;
class FFmpegDecoder;

class FFmpegObject : public QQuickItem
{
    Q_OBJECT
    
    // MPV 호환 속성들
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged)
    Q_PROPERTY(double position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    
    // 비디오 정보 속성들
    Q_PROPERTY(int videoWidth READ videoWidth NOTIFY videoSizeChanged)
    Q_PROPERTY(int videoHeight READ videoHeight NOTIFY videoSizeChanged)
    Q_PROPERTY(QString videoCodec READ videoCodec NOTIFY videoCodecChanged)
    Q_PROPERTY(QString pixelFormat READ pixelFormat NOTIFY pixelFormatChanged)

public:
    explicit FFmpegObject(QQuickItem *parent = nullptr);
    ~FFmpegObject();

    // 속성 getter/setter
    QString source() const { return m_source; }
    void setSource(const QString &source);
    
    bool playing() const { return m_playing; }
    bool paused() const { return m_paused; }
    
    double position() const { return m_position; }
    void setPosition(double position);
    
    double duration() const { return m_duration; }
    
    double volume() const { return m_volume; }
    void setVolume(double volume);
    
    bool muted() const { return m_muted; }
    void setMuted(bool muted);
    
    int videoWidth() const { return m_videoWidth; }
    int videoHeight() const { return m_videoHeight; }
    QString videoCodec() const { return m_videoCodec; }
    QString pixelFormat() const { return m_pixelFormat; }

public slots:
    // MPV 호환 메서드들
    void play();
    void pause();
    void stop();
    void seek(double position);
    void stepForward();
    void stepBackward();
    void frameStep();
    void frameBackStep();
    void loadFile(const QString &file);
    void screenshot(const QString &filename = QString());
    
    // MPV 호환 속성 메서드들
    void setProperty(const QString &name, const QVariant &value);
    QVariant getProperty(const QString &name);
    void command(const QVariantList &params);

signals:
    // MPV 호환 시그널들
    void sourceChanged();
    void playingChanged();
    void pausedChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void mutedChanged();
    void videoSizeChanged();
    void videoCodecChanged();
    void pixelFormatChanged();
    
    // 이벤트 시그널들
    void fileLoaded();
    void fileStarted();
    void fileEnded();
    void endOfFile();
    void seeked();
    void error(const QString &message);

protected:
    // Qt Quick 렌더링
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;
    void itemChange(ItemChange change, const ItemChangeData &value) override;

private slots:
    void onFrameReady();
    void onPositionUpdate();
    void onDecoderError(const QString &error);

private:
    void initializeFFmpeg();
    void cleanup();
    void updateMediaInfo();
    void updatePosition();

    // 속성 변수들
    QString m_source;
    bool m_playing = false;
    bool m_paused = false;
    double m_position = 0.0;
    double m_duration = 0.0;
    double m_volume = 1.0;
    bool m_muted = false;
    
    // 비디오 정보
    int m_videoWidth = 0;
    int m_videoHeight = 0;
    QString m_videoCodec;
    QString m_pixelFormat;
    
    // 내부 객체들
    FFmpegDecoder* m_decoder = nullptr;
    QTimer* m_positionTimer = nullptr;
    bool m_initialized = false;
};

#endif // FFMPEGOBJECT_H 