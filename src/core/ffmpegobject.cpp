#include "ffmpegobject.h"
#include <QDebug>
#include <QOpenGLContext>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <QOpenGLTexture>
#include <QOpenGLFramebufferObject>
#include <QThread>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
#include <libavutil/time.h>
}

// FFmpeg 디코더 클래스
class FFmpegDecoder : public QObject {
    Q_OBJECT

public:
    FFmpegDecoder(QObject *parent = nullptr) : QObject(parent) {
        // FFmpeg 초기화 (한 번만)
        static bool initialized = false;
        if (!initialized) {
            av_log_set_level(AV_LOG_INFO);
            qDebug() << "FFmpeg version:" << av_version_info();
            initialized = true;
        }
    }

    ~FFmpegDecoder() {
        cleanup();
    }

    bool openFile(const QString &filename) {
        cleanup();
        
        m_filename = filename;
        
        // 포맷 컨텍스트 할당
        m_formatContext = avformat_alloc_context();
        if (!m_formatContext) {
            qDebug() << "Failed to allocate format context";
            return false;
        }

        // 파일 열기
        if (avformat_open_input(&m_formatContext, filename.toUtf8().constData(), nullptr, nullptr) < 0) {
            qDebug() << "Failed to open file:" << filename;
            return false;
        }

        // 스트림 정보 찾기
        if (avformat_find_stream_info(m_formatContext, nullptr) < 0) {
            qDebug() << "Failed to find stream info";
            return false;
        }

        // 비디오 스트림 찾기
        for (unsigned int i = 0; i < m_formatContext->nb_streams; i++) {
            if (m_formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                m_videoStreamIndex = i;
                break;
            }
        }

        if (m_videoStreamIndex == -1) {
            qDebug() << "No video stream found";
            return false;
        }

        // 코덱 찾기
        AVCodecParameters* codecParams = m_formatContext->streams[m_videoStreamIndex]->codecpar;
        const AVCodec* codec = avcodec_find_decoder(codecParams->codec_id);
        if (!codec) {
            qDebug() << "Codec not found";
            return false;
        }

        // 코덱 컨텍스트 할당
        m_codecContext = avcodec_alloc_context3(codec);
        if (!m_codecContext) {
            qDebug() << "Failed to allocate codec context";
            return false;
        }

        // 코덱 파라미터 복사
        if (avcodec_parameters_to_context(m_codecContext, codecParams) < 0) {
            qDebug() << "Failed to copy codec parameters";
            return false;
        }

        // 코덱 열기
        if (avcodec_open2(m_codecContext, codec, nullptr) < 0) {
            qDebug() << "Failed to open codec";
            return false;
        }

        // 프레임과 패킷 할당
        m_frame = av_frame_alloc();
        m_packet = av_packet_alloc();

        if (!m_frame || !m_packet) {
            qDebug() << "Failed to allocate frame/packet";
            return false;
        }

        // 스케일링 컨텍스트 초기화
        m_swsContext = sws_getContext(
            m_codecContext->width, m_codecContext->height, m_codecContext->pix_fmt,
            m_codecContext->width, m_codecContext->height, AV_PIX_FMT_RGB24,
            SWS_BILINEAR, nullptr, nullptr, nullptr
        );

        if (!m_swsContext) {
            qDebug() << "Failed to create scaling context";
            return false;
        }

        // RGB 프레임 할당
        m_rgbFrame = av_frame_alloc();
        int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, m_codecContext->width, m_codecContext->height, 1);
        m_rgbBuffer = (uint8_t*)av_malloc(numBytes * sizeof(uint8_t));
        av_image_fill_arrays(m_rgbFrame->data, m_rgbFrame->linesize, m_rgbBuffer, AV_PIX_FMT_RGB24, m_codecContext->width, m_codecContext->height, 1);

        qDebug() << "File opened successfully:" << filename;
        qDebug() << "Video size:" << m_codecContext->width << "x" << m_codecContext->height;
        qDebug() << "Codec:" << avcodec_get_name(codecParams->codec_id);
        
        // ProRes 특별 정보
        if (codecParams->codec_id == AV_CODEC_ID_PRORES) {
            qDebug() << "🎬 ProRes file detected!";
        }

        return true;
    }

    bool decodeFrame() {
        if (!m_formatContext || !m_codecContext) return false;

        while (av_read_frame(m_formatContext, m_packet) >= 0) {
            if (m_packet->stream_index == m_videoStreamIndex) {
                int ret = avcodec_send_packet(m_codecContext, m_packet);
                if (ret < 0) {
                    av_packet_unref(m_packet);
                    continue;
                }

                ret = avcodec_receive_frame(m_codecContext, m_frame);
                if (ret == 0) {
                    // RGB로 변환
                    sws_scale(m_swsContext, m_frame->data, m_frame->linesize, 0, m_codecContext->height, m_rgbFrame->data, m_rgbFrame->linesize);
                    
                    av_packet_unref(m_packet);
                    emit frameReady();
                    return true;
                } else if (ret == AVERROR(EAGAIN)) {
                    av_packet_unref(m_packet);
                    continue;
                }
            }
            av_packet_unref(m_packet);
        }
        return false;
    }

    QImage getCurrentFrame() {
        if (!m_rgbFrame || !m_codecContext) return QImage();
        
        return QImage(m_rgbFrame->data[0], m_codecContext->width, m_codecContext->height, m_rgbFrame->linesize[0], QImage::Format_RGB888);
    }

    double getDuration() const {
        if (!m_formatContext) return 0.0;
        return (double)m_formatContext->duration / AV_TIME_BASE;
    }

    int getWidth() const { return m_codecContext ? m_codecContext->width : 0; }
    int getHeight() const { return m_codecContext ? m_codecContext->height : 0; }
    QString getCodecName() const { return m_codecContext ? avcodec_get_name(m_codecContext->codec_id) : ""; }

signals:
    void frameReady();

private:
    void cleanup() {
        if (m_swsContext) {
            sws_freeContext(m_swsContext);
            m_swsContext = nullptr;
        }
        if (m_rgbBuffer) {
            av_free(m_rgbBuffer);
            m_rgbBuffer = nullptr;
        }
        if (m_rgbFrame) {
            av_frame_free(&m_rgbFrame);
        }
        if (m_frame) {
            av_frame_free(&m_frame);
        }
        if (m_packet) {
            av_packet_free(&m_packet);
        }
        if (m_codecContext) {
            avcodec_free_context(&m_codecContext);
        }
        if (m_formatContext) {
            avformat_close_input(&m_formatContext);
        }
        m_videoStreamIndex = -1;
    }

    QString m_filename;
    AVFormatContext* m_formatContext = nullptr;
    AVCodecContext* m_codecContext = nullptr;
    AVFrame* m_frame = nullptr;
    AVFrame* m_rgbFrame = nullptr;
    AVPacket* m_packet = nullptr;
    SwsContext* m_swsContext = nullptr;
    uint8_t* m_rgbBuffer = nullptr;
    int m_videoStreamIndex = -1;
};

// FFmpegObject 구현
FFmpegObject::FFmpegObject(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
    
    m_decoder = new FFmpegDecoder(this);
    connect(m_decoder, &FFmpegDecoder::frameReady, this, &FFmpegObject::onFrameReady);
    
    m_positionTimer = new QTimer(this);
    connect(m_positionTimer, &QTimer::timeout, this, &FFmpegObject::onPositionUpdate);
    
    qDebug() << "FFmpegObject created";
}

FFmpegObject::~FFmpegObject()
{
    cleanup();
}

void FFmpegObject::setSource(const QString &source)
{
    if (m_source == source) return;
    
    m_source = source;
    emit sourceChanged();
    
    if (!source.isEmpty()) {
        loadFile(source);
    }
}

void FFmpegObject::setPosition(double position)
{
    if (qAbs(m_position - position) < 0.1) return;
    
    m_position = position;
    emit positionChanged();
    
    // TODO: 실제 seek 구현
}

void FFmpegObject::setVolume(double volume)
{
    if (qAbs(m_volume - volume) < 0.01) return;
    
    m_volume = volume;
    emit volumeChanged();
}

void FFmpegObject::setMuted(bool muted)
{
    if (m_muted == muted) return;
    
    m_muted = muted;
    emit mutedChanged();
}

void FFmpegObject::play()
{
    if (m_playing) return;
    
    m_playing = true;
    m_paused = false;
    
    // 프레임 디코딩 시작
    if (m_decoder) {
        QTimer::singleShot(0, [this]() {
            if (m_decoder->decodeFrame()) {
                update(); // QQuickItem 업데이트
            }
        });
    }
    
    m_positionTimer->start(100); // 100ms마다 위치 업데이트
    
    emit playingChanged();
    emit pausedChanged();
    emit fileStarted();
    
    qDebug() << "Playback started";
}

void FFmpegObject::pause()
{
    if (!m_playing || m_paused) return;
    
    m_paused = true;
    m_positionTimer->stop();
    
    emit pausedChanged();
    qDebug() << "Playback paused";
}

void FFmpegObject::stop()
{
    if (!m_playing) return;
    
    m_playing = false;
    m_paused = false;
    m_position = 0.0;
    
    m_positionTimer->stop();
    
    emit playingChanged();
    emit pausedChanged();
    emit positionChanged();
    emit fileEnded();
    
    qDebug() << "Playback stopped";
}

void FFmpegObject::seek(double position)
{
    setPosition(position);
    emit seeked();
}

void FFmpegObject::stepForward()
{
    // 1초 앞으로
    seek(m_position + 1.0);
}

void FFmpegObject::stepBackward()
{
    // 1초 뒤로
    seek(qMax(0.0, m_position - 1.0));
}

void FFmpegObject::frameStep()
{
    // 한 프레임 앞으로 (30fps 기준)
    seek(m_position + 1.0/30.0);
}

void FFmpegObject::frameBackStep()
{
    // 한 프레임 뒤로
    seek(qMax(0.0, m_position - 1.0/30.0));
}

void FFmpegObject::loadFile(const QString &file)
{
    qDebug() << "Loading file:" << file;
    
    if (m_decoder->openFile(file)) {
        updateMediaInfo();
        emit fileLoaded();
        qDebug() << "File loaded successfully";
    } else {
        emit error("Failed to load file: " + file);
        qDebug() << "Failed to load file:" << file;
    }
}

void FFmpegObject::screenshot(const QString &filename)
{
    Q_UNUSED(filename)
    // TODO: 스크린샷 구현
    qDebug() << "Screenshot requested";
}

void FFmpegObject::setProperty(const QString &name, const QVariant &value)
{
    // MPV 호환 속성 설정
    qDebug() << "Setting property:" << name << "=" << value;
    
    if (name == "volume") {
        setVolume(value.toDouble());
    } else if (name == "mute") {
        setMuted(value.toBool());
    }
    // 추가 속성들...
}

QVariant FFmpegObject::getProperty(const QString &name)
{
    // MPV 호환 속성 가져오기
    if (name == "volume") return m_volume;
    if (name == "mute") return m_muted;
    if (name == "duration") return m_duration;
    if (name == "time-pos") return m_position;
    
    return QVariant();
}

void FFmpegObject::command(const QVariantList &params)
{
    if (params.isEmpty()) return;
    
    QString cmd = params[0].toString();
    qDebug() << "Command:" << cmd << "params:" << params;
    
    if (cmd == "play") play();
    else if (cmd == "pause") pause();
    else if (cmd == "stop") stop();
    else if (cmd == "seek" && params.size() > 1) seek(params[1].toDouble());
}

QSGNode *FFmpegObject::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    QSGSimpleTextureNode *node = static_cast<QSGSimpleTextureNode *>(oldNode);
    if (!node) {
        node = new QSGSimpleTextureNode();
    }

    if (m_decoder) {
        QImage frame = m_decoder->getCurrentFrame();
        if (!frame.isNull()) {
            QSGTexture *texture = window()->createTextureFromImage(frame);
            node->setTexture(texture);
            node->setRect(boundingRect());
        }
    }

    return node;
}

void FFmpegObject::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange && value.window) {
        // 윈도우가 변경될 때 처리
    }
    QQuickItem::itemChange(change, value);
}

void FFmpegObject::onFrameReady()
{
    update(); // QQuickItem 다시 그리기
}

void FFmpegObject::onPositionUpdate()
{
    if (m_playing && !m_paused) {
        m_position += 0.1; // 100ms 증가
        if (m_position >= m_duration) {
            stop();
            emit endOfFile();
        } else {
            emit positionChanged();
        }
    }
}

void FFmpegObject::onDecoderError(const QString &error)
{
    emit this->error(error);
}

void FFmpegObject::initializeFFmpeg()
{
    // FFmpeg 초기화는 디코더에서 처리
    m_initialized = true;
}

void FFmpegObject::cleanup()
{
    if (m_positionTimer) {
        m_positionTimer->stop();
    }
    // 디코더는 자동으로 정리됨
}

void FFmpegObject::updateMediaInfo()
{
    if (!m_decoder) return;
    
    m_duration = m_decoder->getDuration();
    m_videoWidth = m_decoder->getWidth();
    m_videoHeight = m_decoder->getHeight();
    m_videoCodec = m_decoder->getCodecName();
    
    // ProRes 특별 처리
    if (m_videoCodec.contains("prores", Qt::CaseInsensitive)) {
        m_pixelFormat = "ProRes";
    }
    
    emit durationChanged();
    emit videoSizeChanged();
    emit videoCodecChanged();
    emit pixelFormatChanged();
    
    qDebug() << "Media info updated - Duration:" << m_duration << "Size:" << m_videoWidth << "x" << m_videoHeight;
}

void FFmpegObject::updatePosition()
{
    // 위치 업데이트 로직
}

#include "ffmpegobject.moc" 