#ifndef FFMPEGENGINE_H
#define FFMPEGENGINE_H

#include <QObject>
#include <QThread>
#include <QMutex>
#include <QWaitCondition>
#include <QQueue>
#include <QTimer>
#include <QDebug>
#include <QVariant>
#include <QString>
#include <memory>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libavutil/imgutils.h>
#include <libavutil/time.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
}

class VideoDecoder;
class AudioDecoder;
class MediaInfo;
class SyncManager;

class FFmpegEngine : public QObject
{
    Q_OBJECT

public:
    explicit FFmpegEngine(QObject *parent = nullptr);
    ~FFmpegEngine();

    // 파일 제어
    bool openFile(const QString& filename);
    void closeFile();
    
    // 재생 제어
    void play();
    void pause();
    void stop();
    bool isPlaying() const { return m_isPlaying; }
    bool isPaused() const { return m_isPaused; }
    
    // 탐색
    void seekToPosition(double position);
    void seekToFrame(int frame);
    
    // 속성 접근자
    QString filename() const { return m_filename; }
    double position() const { return m_position; }
    double duration() const { return m_duration; }
    double fps() const { return m_fps; }
    int frameCount() const { return m_frameCount; }
    
    // 비디오 정보
    QString videoCodec() const { return m_videoCodec; }
    QString videoFormat() const { return m_videoFormat; }
    QString videoResolution() const { return m_videoResolution; }
    QString mediaTitle() const { return m_mediaTitle; }
    
    // 타임코드
    QString timecode() const { return m_timecode; }
    int timecodeFormat() const { return m_timecodeFormat; }
    void setTimecodeFormat(int format) { m_timecodeFormat = format; }
    
    // 프레임 접근
    AVFrame* getCurrentVideoFrame();
    AVFrame* getCurrentAudioFrame();
    
    // 설정
    void setProperty(const QString& name, const QVariant& value);
    QVariant getProperty(const QString& name);

signals:
    void filenameChanged(const QString& filename);
    void positionChanged(double position);
    void durationChanged(double duration);
    void fpsChanged(double fps);
    void frameCountChanged(int count);
    void playingChanged(bool playing);
    void pauseChanged(bool paused);
    void videoCodecChanged(const QString& codec);
    void videoFormatChanged(const QString& format);
    void videoResolutionChanged(const QString& resolution);
    void mediaTitleChanged(const QString& title);
    void timecodeChanged(const QString& timecode);
    void videoFrameReady(AVFrame* frame);
    void audioFrameReady(AVFrame* frame);
    void endReached();
    void error(const QString& message);

public slots:
    void updatePosition();
    void handleVideoFrame(AVFrame* frame);
    void handleAudioFrame(AVFrame* frame);
    void handleEndOfStream();

private slots:
    void onPositionTimer();

private:
    void initializeFFmpeg();
    void cleanupFFmpeg();
    void updateTimecode();
    void calculateFrameCount();
    void updateMediaInfo();
    
    // FFmpeg 컨텍스트
    AVFormatContext* m_formatContext;
    int m_videoStreamIndex;
    int m_audioStreamIndex;
    
    // 디코더
    VideoDecoder* m_videoDecoder;
    AudioDecoder* m_audioDecoder;
    MediaInfo* m_mediaInfo;
    SyncManager* m_syncManager;
    
    // 스레드
    QThread* m_demuxThread;
    QThread* m_videoThread;
    QThread* m_audioThread;
    
    // 상태
    QString m_filename;
    bool m_isPlaying;
    bool m_isPaused;
    double m_position;
    double m_duration;
    double m_fps;
    int m_frameCount;
    
    // 비디오 정보
    QString m_videoCodec;
    QString m_videoFormat;
    QString m_videoResolution;
    QString m_mediaTitle;
    
    // 타임코드
    QString m_timecode;
    int m_timecodeFormat;
    
    // 타이머
    QTimer* m_positionTimer;
    
    // 동기화
    mutable QMutex m_mutex;
    QWaitCondition m_condition;
    
    // 현재 프레임
    AVFrame* m_currentVideoFrame;
    AVFrame* m_currentAudioFrame;
};

#endif // FFMPEGENGINE_H 