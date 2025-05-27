#ifndef AUDIODECODER_H
#define AUDIODECODER_H

#include <QObject>
#include <QThread>
#include <QMutex>
#include <QQueue>
#include <QWaitCondition>
#include <QString>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libswresample/swresample.h>
}

class AudioDecoder : public QObject
{
    Q_OBJECT

public:
    explicit AudioDecoder(QObject *parent = nullptr);
    ~AudioDecoder();

    bool initialize(AVFormatContext* formatContext, int streamIndex);
    void cleanup();
    
    bool seekToPosition(double position);
    
    void start();
    void stop();
    void pause();
    void resume();
    
    // 오디오 정보
    QString getCodecName() const { return m_codecName; }
    int getSampleRate() const { return m_sampleRate; }
    int getChannels() const { return m_channels; }
    QString getChannelLayout() const { return m_channelLayout; }

signals:
    void frameReady(AVFrame* frame);
    void endOfStream();
    void error(const QString& message);

public slots:
    void processPacket(AVPacket* packet);

private slots:
    void decodeLoop();

private:
    AVFrame* resampleFrame(AVFrame* srcFrame);
    
    AVFormatContext* m_formatContext;
    AVCodecContext* m_codecContext;
    AVStream* m_stream;
    const AVCodec* m_codec;
    SwrContext* m_swrContext;
    
    // 오디오 정보
    QString m_codecName;
    int m_sampleRate;
    int m_channels;
    QString m_channelLayout;
    
    // 스레드 제어
    QThread* m_thread;
    bool m_running;
    bool m_paused;
    
    // 패킷 큐
    QQueue<AVPacket*> m_packetQueue;
    mutable QMutex m_queueMutex;
    QWaitCondition m_queueCondition;
    
    static constexpr int MAX_QUEUE_SIZE = 200;
};

#endif // AUDIODECODER_H 