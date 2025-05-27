#ifndef VIDEODECODER_H
#define VIDEODECODER_H

#include <QObject>
#include <QThread>
#include <QMutex>
#include <QQueue>
#include <QWaitCondition>
#include <QSize>
#include <QVector>
#include <QString>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libavutil/hwcontext.h>
#include <libavutil/pixfmt.h>
#include <libavutil/pixdesc.h>
#include <libswscale/swscale.h>
}

class VideoDecoder : public QObject
{
    Q_OBJECT

public:
    explicit VideoDecoder(QObject *parent = nullptr);
    ~VideoDecoder();

    bool initialize(AVFormatContext* formatContext, int streamIndex);
    void cleanup();
    
    bool seekToFrame(int frameNumber, bool exact = true);
    bool seekToPosition(double position);
    
    void start();
    void stop();
    void pause();
    void resume();
    
    // 하드웨어 가속
    bool initHardwareDecoding();
    
    // 프레임 정보
    int getFrameCount() const { return m_frameCount; }
    double getFps() const { return m_fps; }
    QString getCodecName() const { return m_codecName; }
    QString getPixelFormat() const { return m_pixelFormat; }
    QSize getResolution() const { return m_resolution; }

signals:
    void frameReady(AVFrame* frame);
    void endOfStream();
    void error(const QString& message);

public slots:
    void processPacket(AVPacket* packet);

private slots:
    void decodeLoop();

private:
    void buildFrameIndex();
    bool decodeToTargetFrame(int targetFrame);
    AVFrame* convertFrame(AVFrame* srcFrame);
    
    // 하드웨어 가속 초기화
    bool initVAAPI();
    bool initD3D11VA();
    bool initVideoToolbox();
    bool initCUDA();
    
    AVFormatContext* m_formatContext;
    AVCodecContext* m_codecContext;
    AVStream* m_stream;
    const AVCodec* m_codec;
    SwsContext* m_swsContext;
    
    // 하드웨어 가속
    AVBufferRef* m_hwDeviceContext;
    AVPixelFormat m_hwPixelFormat;
    bool m_useHardwareDecoding;
    
    // 프레임 인덱스 (정확한 탐색용)
    QVector<int64_t> m_frameIndex;
    int m_frameCount;
    double m_fps;
    
    // 코덱 정보
    QString m_codecName;
    QString m_pixelFormat;
    QSize m_resolution;
    
    // 스레드 제어
    QThread* m_thread;
    bool m_running;
    bool m_paused;
    
    // 패킷 큐
    QQueue<AVPacket*> m_packetQueue;
    mutable QMutex m_queueMutex;
    QWaitCondition m_queueCondition;
    
    // 현재 상태
    int m_currentFrame;
    double m_currentPosition;
    
    static constexpr int MAX_QUEUE_SIZE = 100;
};

#endif // VIDEODECODER_H 