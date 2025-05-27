#include "AudioDecoder.h"
#include <QDebug>
#include <QMutexLocker>
#include <QThread>

AudioDecoder::AudioDecoder(QObject *parent)
    : QObject(parent)
    , m_formatContext(nullptr)
    , m_codecContext(nullptr)
    , m_stream(nullptr)
    , m_codec(nullptr)
    , m_swrContext(nullptr)
    , m_sampleRate(0)
    , m_channels(0)
    , m_thread(nullptr)
    , m_running(false)
    , m_paused(false)
{
}

AudioDecoder::~AudioDecoder()
{
    cleanup();
}

bool AudioDecoder::initialize(AVFormatContext* formatContext, int streamIndex)
{
    if (!formatContext || streamIndex < 0) {
        emit error("Invalid format context or stream index");
        return false;
    }
    
    m_formatContext = formatContext;
    m_stream = formatContext->streams[streamIndex];
    
    // 코덱 찾기
    m_codec = avcodec_find_decoder(m_stream->codecpar->codec_id);
    if (!m_codec) {
        emit error("Audio codec not found");
        return false;
    }
    
    // 코덱 컨텍스트 생성
    m_codecContext = avcodec_alloc_context3(m_codec);
    if (!m_codecContext) {
        emit error("Failed to allocate audio codec context");
        return false;
    }
    
    // 스트림 파라미터를 코덱 컨텍스트로 복사
    if (avcodec_parameters_to_context(m_codecContext, m_stream->codecpar) < 0) {
        emit error("Failed to copy audio codec parameters");
        cleanup();
        return false;
    }
    
    // 코덱 열기
    if (avcodec_open2(m_codecContext, m_codec, nullptr) < 0) {
        emit error("Failed to open audio codec");
        cleanup();
        return false;
    }
    
    // 오디오 정보 추출
    m_codecName = QString(m_codec->name);
    m_sampleRate = m_codecContext->sample_rate;
    m_channels = m_codecContext->channels;
    
    // 채널 레이아웃 정보 (최신 FFmpeg API 사용)
    char layoutName[256];
    if (m_codecContext->ch_layout.nb_channels > 0) {
        av_channel_layout_describe(&m_codecContext->ch_layout, layoutName, sizeof(layoutName));
        m_channelLayout = QString(layoutName);
    } else {
        m_channelLayout = QString("unknown");
    }
    
    // 리샘플러 초기화 (필요한 경우)
    if (m_codecContext->sample_fmt != AV_SAMPLE_FMT_S16) {
        m_swrContext = swr_alloc();
        if (!m_swrContext) {
            emit error("Failed to allocate resampler");
            cleanup();
            return false;
        }
        
        // 리샘플러 설정 (최신 FFmpeg API 사용)
        swr_alloc_set_opts2(&m_swrContext,
                           &m_codecContext->ch_layout, AV_SAMPLE_FMT_S16, m_codecContext->sample_rate,
                           &m_codecContext->ch_layout, m_codecContext->sample_fmt, m_codecContext->sample_rate,
                           0, nullptr);
        
        if (swr_init(m_swrContext) < 0) {
            emit error("Failed to initialize resampler");
            cleanup();
            return false;
        }
    }
    
    qDebug() << "Audio decoder initialized:"
             << "Codec:" << m_codecName
             << "Sample rate:" << m_sampleRate
             << "Channels:" << m_channels
             << "Layout:" << m_channelLayout;
    
    return true;
}

void AudioDecoder::cleanup()
{
    stop();
    
    if (m_swrContext) {
        swr_free(&m_swrContext);
    }
    
    if (m_codecContext) {
        avcodec_free_context(&m_codecContext);
    }
    
    // 패킷 큐 정리
    QMutexLocker locker(&m_queueMutex);
    while (!m_packetQueue.isEmpty()) {
        AVPacket* packet = m_packetQueue.dequeue();
        av_packet_free(&packet);
    }
}

bool AudioDecoder::seekToPosition(double position)
{
    if (!m_formatContext || position < 0) return false;
    
    // 오디오 스트림에서 탐색
    int64_t timestamp = position * AV_TIME_BASE;
    if (av_seek_frame(m_formatContext, m_stream->index, timestamp, AVSEEK_FLAG_BACKWARD) >= 0) {
        // 코덱 플러시
        if (m_codecContext) {
            avcodec_flush_buffers(m_codecContext);
        }
        
        // 패킷 큐 정리
        QMutexLocker locker(&m_queueMutex);
        while (!m_packetQueue.isEmpty()) {
            AVPacket* packet = m_packetQueue.dequeue();
            av_packet_free(&packet);
        }
        
        return true;
    }
    
    return false;
}

void AudioDecoder::start()
{
    if (m_running) return;
    
    m_running = true;
    m_paused = false;
    
    // 별도 스레드에서 디코딩 실행
    m_thread = QThread::create([this]() {
        decodeLoop();
    });
    
    connect(m_thread, &QThread::finished, m_thread, &QThread::deleteLater);
    m_thread->start();
    
    qDebug() << "Audio decoder started";
}

void AudioDecoder::stop()
{
    if (!m_running) return;
    
    m_running = false;
    m_paused = false;
    
    // 스레드 깨우기
    m_queueCondition.wakeAll();
    
    if (m_thread) {
        m_thread->wait(3000); // 3초 대기
        if (m_thread->isRunning()) {
            m_thread->terminate();
            m_thread->wait(1000);
        }
        m_thread = nullptr;
    }
    
    qDebug() << "Audio decoder stopped";
}

void AudioDecoder::pause()
{
    QMutexLocker locker(&m_queueMutex);
    m_paused = true;
}

void AudioDecoder::resume()
{
    QMutexLocker locker(&m_queueMutex);
    m_paused = false;
    m_queueCondition.wakeAll();
}

void AudioDecoder::processPacket(AVPacket* packet)
{
    QMutexLocker locker(&m_queueMutex);
    
    if (m_packetQueue.size() >= MAX_QUEUE_SIZE) {
        // 큐가 가득 찬 경우 가장 오래된 패킷 제거
        AVPacket* oldPacket = m_packetQueue.dequeue();
        av_packet_free(&oldPacket);
    }
    
    // 패킷 복사하여 큐에 추가
    AVPacket* packetCopy = av_packet_alloc();
    av_packet_ref(packetCopy, packet);
    m_packetQueue.enqueue(packetCopy);
    
    m_queueCondition.wakeOne();
}

void AudioDecoder::decodeLoop()
{
    AVFrame* frame = av_frame_alloc();
    AVPacket* packet = av_packet_alloc();
    
    while (m_running) {
        // 일시정지 상태 확인
        {
            QMutexLocker locker(&m_queueMutex);
            while (m_paused && m_running) {
                m_queueCondition.wait(&m_queueMutex);
            }
            
            if (!m_running) break;
        }
        
        // 패킷 읽기
        int ret = av_read_frame(m_formatContext, packet);
        if (ret < 0) {
            if (ret == AVERROR_EOF) {
                emit endOfStream();
            } else {
                emit error("Failed to read audio frame");
            }
            break;
        }
        
        // 오디오 스트림 패킷인지 확인
        if (packet->stream_index != m_stream->index) {
            av_packet_unref(packet);
            continue;
        }
        
        // 패킷을 코덱으로 전송
        ret = avcodec_send_packet(m_codecContext, packet);
        av_packet_unref(packet);
        
        if (ret < 0) {
            qDebug() << "Error sending audio packet to decoder";
            continue;
        }
        
        // 디코딩된 프레임 받기
        while (ret >= 0 && m_running) {
            ret = avcodec_receive_frame(m_codecContext, frame);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
                break;
            } else if (ret < 0) {
                qDebug() << "Error during audio decoding";
                break;
            }
            
            // 리샘플링 (필요한 경우)
            AVFrame* outputFrame = frame;
            if (m_swrContext) {
                outputFrame = resampleFrame(frame);
            }
            
            // 프레임 준비 완료 신호 발송
            emit frameReady(outputFrame ? outputFrame : frame);
            
            // 메모리 정리
            if (outputFrame && outputFrame != frame) {
                av_frame_free(&outputFrame);
            }
            
            av_frame_unref(frame);
        }
    }
    
    av_frame_free(&frame);
    av_packet_free(&packet);
    
    qDebug() << "Audio decode loop finished";
}

AVFrame* AudioDecoder::resampleFrame(AVFrame* srcFrame)
{
    if (!m_swrContext || !srcFrame) return nullptr;
    
    // 출력 프레임 할당
    AVFrame* dstFrame = av_frame_alloc();
    if (!dstFrame) return nullptr;
    
    // 출력 프레임 설정 (최신 FFmpeg API 사용)
    dstFrame->format = AV_SAMPLE_FMT_S16;
    av_channel_layout_copy(&dstFrame->ch_layout, &srcFrame->ch_layout);
    dstFrame->sample_rate = srcFrame->sample_rate;
    dstFrame->nb_samples = srcFrame->nb_samples;
    
    // 버퍼 할당
    if (av_frame_get_buffer(dstFrame, 0) < 0) {
        av_frame_free(&dstFrame);
        return nullptr;
    }
    
    // 리샘플링 수행
    int ret = swr_convert(m_swrContext,
                         dstFrame->data, dstFrame->nb_samples,
                         (const uint8_t**)srcFrame->data, srcFrame->nb_samples);
    
    if (ret < 0) {
        av_frame_free(&dstFrame);
        return nullptr;
    }
    
    // 타임스탬프 복사
    dstFrame->pts = srcFrame->pts;
    dstFrame->pkt_dts = srcFrame->pkt_dts;
    
    return dstFrame;
} 