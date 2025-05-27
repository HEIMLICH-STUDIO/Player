#include "VideoDecoder.h"
#include <QDebug>
#include <QMutexLocker>
#include <QThread>

extern "C" {
#include <libavutil/imgutils.h>
#include <libavutil/hwcontext.h>
}

VideoDecoder::VideoDecoder(QObject *parent)
    : QObject(parent)
    , m_formatContext(nullptr)
    , m_codecContext(nullptr)
    , m_stream(nullptr)
    , m_codec(nullptr)
    , m_swsContext(nullptr)
    , m_hwDeviceContext(nullptr)
    , m_hwPixelFormat(AV_PIX_FMT_NONE)
    , m_useHardwareDecoding(false)
    , m_frameCount(0)
    , m_fps(0.0)
    , m_thread(nullptr)
    , m_running(false)
    , m_paused(false)
    , m_currentFrame(0)
    , m_currentPosition(0.0)
{
}

VideoDecoder::~VideoDecoder()
{
    cleanup();
}

bool VideoDecoder::initialize(AVFormatContext* formatContext, int streamIndex)
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
        emit error("Codec not found");
        return false;
    }
    
    // 코덱 컨텍스트 생성
    m_codecContext = avcodec_alloc_context3(m_codec);
    if (!m_codecContext) {
        emit error("Failed to allocate codec context");
        return false;
    }
    
    // 스트림 파라미터를 코덱 컨텍스트로 복사
    if (avcodec_parameters_to_context(m_codecContext, m_stream->codecpar) < 0) {
        emit error("Failed to copy codec parameters");
        cleanup();
        return false;
    }
    
    // 하드웨어 가속 시도
    if (initHardwareDecoding()) {
        qDebug() << "Hardware decoding enabled";
    } else {
        qDebug() << "Using software decoding";
    }
    
    // 코덱 열기
    if (avcodec_open2(m_codecContext, m_codec, nullptr) < 0) {
        emit error("Failed to open codec");
        cleanup();
        return false;
    }
    
    // 비디오 정보 추출
    m_codecName = QString(m_codec->name);
    m_pixelFormat = QString(av_get_pix_fmt_name(m_codecContext->pix_fmt));
    m_resolution = QSize(m_codecContext->width, m_codecContext->height);
    
    // FPS 계산
    AVRational frameRate = av_guess_frame_rate(m_formatContext, m_stream, nullptr);
    if (frameRate.num > 0 && frameRate.den > 0) {
        m_fps = static_cast<double>(frameRate.num) / frameRate.den;
    }
    
    // 프레임 수 계산
    if (m_stream->nb_frames > 0) {
        m_frameCount = m_stream->nb_frames;
    } else if (m_formatContext->duration != AV_NOPTS_VALUE && m_fps > 0) {
        double duration = static_cast<double>(m_formatContext->duration) / AV_TIME_BASE;
        m_frameCount = static_cast<int>(duration * m_fps);
    }
    
    // 프레임 인덱스 구축 (정확한 탐색을 위해)
    buildFrameIndex();
    
    qDebug() << "Video decoder initialized:"
             << "Codec:" << m_codecName
             << "Resolution:" << m_resolution
             << "FPS:" << m_fps
             << "Frame count:" << m_frameCount;
    
    return true;
}

void VideoDecoder::cleanup()
{
    stop();
    
    if (m_swsContext) {
        sws_freeContext(m_swsContext);
        m_swsContext = nullptr;
    }
    
    if (m_hwDeviceContext) {
        av_buffer_unref(&m_hwDeviceContext);
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

bool VideoDecoder::initHardwareDecoding()
{
    // 하드웨어 가속 타입들 시도
    const AVHWDeviceType hwTypes[] = {
#ifdef _WIN32
        AV_HWDEVICE_TYPE_D3D11VA,
        AV_HWDEVICE_TYPE_DXVA2,
#elif defined(__APPLE__)
        AV_HWDEVICE_TYPE_VIDEOTOOLBOX,
#else
        AV_HWDEVICE_TYPE_VAAPI,
        AV_HWDEVICE_TYPE_VDPAU,
#endif
        AV_HWDEVICE_TYPE_CUDA,
        AV_HWDEVICE_TYPE_NONE
    };
    
    for (int i = 0; hwTypes[i] != AV_HWDEVICE_TYPE_NONE; i++) {
        // 코덱이 이 하드웨어 타입을 지원하는지 확인
        for (int j = 0;; j++) {
            const AVCodecHWConfig* config = avcodec_get_hw_config(m_codec, j);
            if (!config) break;
            
            if (config->methods & AV_CODEC_HW_CONFIG_METHOD_HW_DEVICE_CTX &&
                config->device_type == hwTypes[i]) {
                
                // 하드웨어 디바이스 컨텍스트 생성 시도
                if (av_hwdevice_ctx_create(&m_hwDeviceContext, hwTypes[i], nullptr, nullptr, 0) == 0) {
                    m_codecContext->hw_device_ctx = av_buffer_ref(m_hwDeviceContext);
                    m_hwPixelFormat = config->pix_fmt;
                    m_useHardwareDecoding = true;
                    
                    qDebug() << "Hardware decoding initialized:" << av_hwdevice_get_type_name(hwTypes[i]);
                    return true;
                }
            }
        }
    }
    
    return false;
}

void VideoDecoder::start()
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
    
    qDebug() << "Video decoder started";
}

void VideoDecoder::stop()
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
    
    qDebug() << "Video decoder stopped";
}

void VideoDecoder::pause()
{
    QMutexLocker locker(&m_queueMutex);
    m_paused = true;
}

void VideoDecoder::resume()
{
    QMutexLocker locker(&m_queueMutex);
    m_paused = false;
    m_queueCondition.wakeAll();
}

bool VideoDecoder::seekToFrame(int frameNumber, bool exact)
{
    if (frameNumber < 0 || frameNumber >= m_frameCount) {
        return false;
    }
    
    // 프레임 인덱스를 사용한 정확한 탐색
    if (exact && frameNumber < m_frameIndex.size()) {
        int64_t timestamp = m_frameIndex[frameNumber];
        if (av_seek_frame(m_formatContext, m_stream->index, timestamp, AVSEEK_FLAG_BACKWARD) >= 0) {
            m_currentFrame = frameNumber;
            
            // 코덱 플러시
            avcodec_flush_buffers(m_codecContext);
            
            // 정확한 프레임까지 디코딩
            return decodeToTargetFrame(frameNumber);
        }
    } else {
        // 근사 탐색
        double position = static_cast<double>(frameNumber) / m_fps;
        return seekToPosition(position);
    }
    
    return false;
}

bool VideoDecoder::seekToPosition(double position)
{
    if (position < 0) return false;
    
    int64_t timestamp = position * AV_TIME_BASE;
    if (av_seek_frame(m_formatContext, -1, timestamp, AVSEEK_FLAG_BACKWARD) >= 0) {
        m_currentPosition = position;
        m_currentFrame = static_cast<int>(position * m_fps);
        
        // 코덱 플러시
        avcodec_flush_buffers(m_codecContext);
        
        return true;
    }
    
    return false;
}

void VideoDecoder::processPacket(AVPacket* packet)
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

void VideoDecoder::decodeLoop()
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
                emit error("Failed to read frame");
            }
            break;
        }
        
        // 비디오 스트림 패킷인지 확인
        if (packet->stream_index != m_stream->index) {
            av_packet_unref(packet);
            continue;
        }
        
        // 패킷을 코덱으로 전송
        ret = avcodec_send_packet(m_codecContext, packet);
        av_packet_unref(packet);
        
        if (ret < 0) {
            qDebug() << "Error sending packet to decoder";
            continue;
        }
        
        // 디코딩된 프레임 받기
        while (ret >= 0 && m_running) {
            ret = avcodec_receive_frame(m_codecContext, frame);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
                break;
            } else if (ret < 0) {
                qDebug() << "Error during decoding";
                break;
            }
            
            // 하드웨어 디코딩된 프레임을 소프트웨어로 전송 (필요한 경우)
            AVFrame* outputFrame = frame;
            if (m_useHardwareDecoding && frame->format == m_hwPixelFormat) {
                AVFrame* swFrame = av_frame_alloc();
                if (av_hwframe_transfer_data(swFrame, frame, 0) >= 0) {
                    outputFrame = swFrame;
                } else {
                    av_frame_free(&swFrame);
                }
            }
            
            // 프레임 변환 (필요한 경우)
            AVFrame* convertedFrame = convertFrame(outputFrame);
            
            // 프레임 준비 완료 신호 발송
            emit frameReady(convertedFrame ? convertedFrame : outputFrame);
            
            // 메모리 정리
            if (convertedFrame && convertedFrame != outputFrame) {
                av_frame_free(&convertedFrame);
            }
            
            if (outputFrame != frame) {
                av_frame_free(&outputFrame);
            }
            
            av_frame_unref(frame);
            
            m_currentFrame++;
        }
    }
    
    av_frame_free(&frame);
    av_packet_free(&packet);
    
    qDebug() << "Video decode loop finished";
}

void VideoDecoder::buildFrameIndex()
{
    if (!m_formatContext || !m_stream) return;
    
    // 간단한 프레임 인덱스 구축
    // 실제 구현에서는 더 정교한 인덱싱이 필요할 수 있음
    m_frameIndex.clear();
    
    if (m_stream->nb_frames > 0) {
        m_frameIndex.reserve(m_stream->nb_frames);
        
        // 균등 분포로 타임스탬프 생성
        int64_t duration = m_stream->duration;
        if (duration > 0) {
            for (int i = 0; i < m_stream->nb_frames; i++) {
                int64_t timestamp = (duration * i) / m_stream->nb_frames;
                m_frameIndex.append(timestamp);
            }
        }
    }
    
    qDebug() << "Frame index built with" << m_frameIndex.size() << "entries";
}

bool VideoDecoder::decodeToTargetFrame(int targetFrame)
{
    if (targetFrame < 0) return false;
    
    AVFrame* frame = av_frame_alloc();
    AVPacket* packet = av_packet_alloc();
    int currentFrame = 0;
    
    while (currentFrame <= targetFrame) {
        int ret = av_read_frame(m_formatContext, packet);
        if (ret < 0) break;
        
        if (packet->stream_index != m_stream->index) {
            av_packet_unref(packet);
            continue;
        }
        
        ret = avcodec_send_packet(m_codecContext, packet);
        av_packet_unref(packet);
        
        if (ret < 0) continue;
        
        while (ret >= 0) {
            ret = avcodec_receive_frame(m_codecContext, frame);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
                break;
            } else if (ret < 0) {
                break;
            }
            
            if (currentFrame == targetFrame) {
                // 목표 프레임에 도달
                emit frameReady(frame);
                av_frame_free(&frame);
                av_packet_free(&packet);
                return true;
            }
            
            currentFrame++;
            av_frame_unref(frame);
        }
    }
    
    av_frame_free(&frame);
    av_packet_free(&packet);
    return false;
}

AVFrame* VideoDecoder::convertFrame(AVFrame* srcFrame)
{
    if (!srcFrame) return nullptr;
    
    // 필요한 경우에만 변환 (예: 픽셀 포맷 변환)
    AVPixelFormat targetFormat = AV_PIX_FMT_YUV420P; // 기본 출력 포맷
    
    if (srcFrame->format == targetFormat) {
        return nullptr; // 변환 불필요
    }
    
    // SwsContext 초기화 (필요한 경우)
    if (!m_swsContext) {
        m_swsContext = sws_getContext(
            srcFrame->width, srcFrame->height, static_cast<AVPixelFormat>(srcFrame->format),
            srcFrame->width, srcFrame->height, targetFormat,
            SWS_BILINEAR, nullptr, nullptr, nullptr
        );
        
        if (!m_swsContext) {
            qDebug() << "Failed to create SwsContext";
            return nullptr;
        }
    }
    
    // 출력 프레임 할당
    AVFrame* dstFrame = av_frame_alloc();
    dstFrame->format = targetFormat;
    dstFrame->width = srcFrame->width;
    dstFrame->height = srcFrame->height;
    
    if (av_frame_get_buffer(dstFrame, 32) < 0) {
        av_frame_free(&dstFrame);
        return nullptr;
    }
    
    // 변환 수행
    sws_scale(m_swsContext,
              srcFrame->data, srcFrame->linesize, 0, srcFrame->height,
              dstFrame->data, dstFrame->linesize);
    
    // 타임스탬프 복사
    dstFrame->pts = srcFrame->pts;
    dstFrame->pkt_dts = srcFrame->pkt_dts;
    
    return dstFrame;
} 