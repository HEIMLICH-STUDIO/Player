#include "FFmpegEngine.h"
#include "VideoDecoder.h"
#include "AudioDecoder.h"
#include "../utils/TimecodeUtils.h"
#include <QDebug>
#include <QThread>
#include <QMutexLocker>
#include <QFileInfo>
#include <QTimer>

FFmpegEngine::FFmpegEngine(QObject *parent)
    : QObject(parent)
    , m_formatContext(nullptr)
    , m_videoStreamIndex(-1)
    , m_audioStreamIndex(-1)
    , m_videoDecoder(nullptr)
    , m_audioDecoder(nullptr)
    , m_mediaInfo(nullptr)
    , m_syncManager(nullptr)
    , m_demuxThread(nullptr)
    , m_videoThread(nullptr)
    , m_audioThread(nullptr)
    , m_isPlaying(false)
    , m_isPaused(false)
    , m_position(0.0)
    , m_duration(0.0)
    , m_fps(0.0)
    , m_frameCount(0)
    , m_timecodeFormat(0)
    , m_positionTimer(new QTimer(this))
    , m_currentVideoFrame(nullptr)
    , m_currentAudioFrame(nullptr)
{
    initializeFFmpeg();
    
    // 위치 업데이트 타이머
    connect(m_positionTimer, &QTimer::timeout, this, &FFmpegEngine::onPositionTimer);
    m_positionTimer->setInterval(16); // 60fps
}

FFmpegEngine::~FFmpegEngine()
{
    closeFile();
    cleanupFFmpeg();
}

void FFmpegEngine::initializeFFmpeg()
{
    // FFmpeg 로그 레벨 설정
    av_log_set_level(AV_LOG_WARNING);
    
    qDebug() << "FFmpeg initialized";
}

void FFmpegEngine::cleanupFFmpeg()
{
    if (m_currentVideoFrame) {
        av_frame_free(&m_currentVideoFrame);
    }
    if (m_currentAudioFrame) {
        av_frame_free(&m_currentAudioFrame);
    }
}

bool FFmpegEngine::openFile(const QString& filename)
{
    closeFile();
    
    QMutexLocker locker(&m_mutex);
    
    // 파일 존재 확인
    QFileInfo fileInfo(filename);
    if (!fileInfo.exists()) {
        emit error("File does not exist: " + filename);
        return false;
    }
    
    // 포맷 컨텍스트 열기
    m_formatContext = avformat_alloc_context();
    if (!m_formatContext) {
        emit error("Failed to allocate format context");
        return false;
    }
    
    if (avformat_open_input(&m_formatContext, filename.toUtf8().constData(), nullptr, nullptr) < 0) {
        emit error("Failed to open file: " + filename);
        avformat_free_context(m_formatContext);
        m_formatContext = nullptr;
        return false;
    }
    
    // 스트림 정보 찾기
    if (avformat_find_stream_info(m_formatContext, nullptr) < 0) {
        emit error("Failed to find stream info");
        closeFile();
        return false;
    }
    
    // 비디오 및 오디오 스트림 찾기
    m_videoStreamIndex = av_find_best_stream(m_formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
    m_audioStreamIndex = av_find_best_stream(m_formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    
    if (m_videoStreamIndex < 0) {
        emit error("No video stream found");
        closeFile();
        return false;
    }
    
    // 비디오 디코더 초기화
    m_videoDecoder = new VideoDecoder(this);
    if (!m_videoDecoder->initialize(m_formatContext, m_videoStreamIndex)) {
        emit error("Failed to initialize video decoder");
        closeFile();
        return false;
    }
    
    connect(m_videoDecoder, &VideoDecoder::frameReady, this, &FFmpegEngine::handleVideoFrame);
    connect(m_videoDecoder, &VideoDecoder::endOfStream, this, &FFmpegEngine::handleEndOfStream);
    connect(m_videoDecoder, &VideoDecoder::error, this, &FFmpegEngine::error);
    
    // 오디오 디코더 초기화 (선택사항)
    if (m_audioStreamIndex >= 0) {
        m_audioDecoder = new AudioDecoder(this);
        if (m_audioDecoder->initialize(m_formatContext, m_audioStreamIndex)) {
            connect(m_audioDecoder, &AudioDecoder::frameReady, this, &FFmpegEngine::handleAudioFrame);
            connect(m_audioDecoder, &AudioDecoder::endOfStream, this, &FFmpegEngine::handleEndOfStream);
            connect(m_audioDecoder, &AudioDecoder::error, this, &FFmpegEngine::error);
        } else {
            delete m_audioDecoder;
            m_audioDecoder = nullptr;
        }
    }
    
    // 미디어 정보 업데이트
    m_filename = filename;
    m_duration = static_cast<double>(m_formatContext->duration) / AV_TIME_BASE;
    m_fps = m_videoDecoder->getFps();
    m_frameCount = m_videoDecoder->getFrameCount();
    
    updateMediaInfo();
    
    // 신호 발송
    emit filenameChanged(m_filename);
    emit durationChanged(m_duration);
    emit fpsChanged(m_fps);
    emit frameCountChanged(m_frameCount);
    
    qDebug() << "File opened successfully:" << filename;
    qDebug() << "Duration:" << m_duration << "seconds";
    qDebug() << "FPS:" << m_fps;
    qDebug() << "Frame count:" << m_frameCount;
    
    return true;
}

void FFmpegEngine::closeFile()
{
    QMutexLocker locker(&m_mutex);
    
    stop();
    
    if (m_videoDecoder) {
        delete m_videoDecoder;
        m_videoDecoder = nullptr;
    }
    
    if (m_audioDecoder) {
        delete m_audioDecoder;
        m_audioDecoder = nullptr;
    }
    
    if (m_formatContext) {
        avformat_close_input(&m_formatContext);
        m_formatContext = nullptr;
    }
    
    // 상태 초기화
    m_filename.clear();
    m_position = 0.0;
    m_duration = 0.0;
    m_fps = 0.0;
    m_frameCount = 0;
    m_videoStreamIndex = -1;
    m_audioStreamIndex = -1;
    
    emit filenameChanged(m_filename);
    emit positionChanged(m_position);
    emit durationChanged(m_duration);
    emit fpsChanged(m_fps);
    emit frameCountChanged(m_frameCount);
}

void FFmpegEngine::play()
{
    QMutexLocker locker(&m_mutex);
    
    if (!m_formatContext || m_isPlaying) return;
    
    m_isPlaying = true;
    m_isPaused = false;
    
    if (m_videoDecoder) {
        m_videoDecoder->start();
    }
    
    if (m_audioDecoder) {
        m_audioDecoder->start();
    }
    
    m_positionTimer->start();
    
    emit playingChanged(m_isPlaying);
    emit pauseChanged(m_isPaused);
    
    qDebug() << "Playback started";
}

void FFmpegEngine::pause()
{
    QMutexLocker locker(&m_mutex);
    
    if (!m_formatContext || !m_isPlaying) return;
    
    m_isPaused = !m_isPaused;
    
    if (m_videoDecoder) {
        if (m_isPaused) {
            m_videoDecoder->pause();
        } else {
            m_videoDecoder->resume();
        }
    }
    
    if (m_audioDecoder) {
        if (m_isPaused) {
            m_audioDecoder->pause();
        } else {
            m_audioDecoder->resume();
        }
    }
    
    if (m_isPaused) {
        m_positionTimer->stop();
    } else {
        m_positionTimer->start();
    }
    
    emit pauseChanged(m_isPaused);
    
    qDebug() << "Playback" << (m_isPaused ? "paused" : "resumed");
}

void FFmpegEngine::stop()
{
    QMutexLocker locker(&m_mutex);
    
    if (!m_isPlaying && !m_isPaused) return;
    
    m_isPlaying = false;
    m_isPaused = false;
    
    m_positionTimer->stop();
    
    if (m_videoDecoder) {
        m_videoDecoder->stop();
    }
    
    if (m_audioDecoder) {
        m_audioDecoder->stop();
    }
    
    m_position = 0.0;
    
    emit playingChanged(m_isPlaying);
    emit pauseChanged(m_isPaused);
    emit positionChanged(m_position);
    
    qDebug() << "Playback stopped";
}

void FFmpegEngine::seekToPosition(double position)
{
    QMutexLocker locker(&m_mutex);
    
    if (!m_formatContext || position < 0 || position > m_duration) return;
    
    m_position = position;
    
    if (m_videoDecoder) {
        m_videoDecoder->seekToPosition(position);
    }
    
    if (m_audioDecoder) {
        m_audioDecoder->seekToPosition(position);
    }
    
    updateTimecode();
    
    emit positionChanged(m_position);
    emit timecodeChanged(m_timecode);
    
    qDebug() << "Seeked to position:" << position;
}

void FFmpegEngine::seekToFrame(int frame)
{
    if (m_fps <= 0) return;
    
    double position = frame / m_fps;
    seekToPosition(position);
}

void FFmpegEngine::updateMediaInfo()
{
    if (!m_formatContext) return;
    
    // 비디오 코덱 정보
    if (m_videoStreamIndex >= 0) {
        AVStream* videoStream = m_formatContext->streams[m_videoStreamIndex];
        const AVCodec* codec = avcodec_find_decoder(videoStream->codecpar->codec_id);
        if (codec) {
            m_videoCodec = QString(codec->name);
            emit videoCodecChanged(m_videoCodec);
        }
        
        m_videoFormat = QString(av_get_pix_fmt_name(static_cast<AVPixelFormat>(videoStream->codecpar->format)));
        emit videoFormatChanged(m_videoFormat);
        
        m_videoResolution = QString("%1x%2").arg(videoStream->codecpar->width).arg(videoStream->codecpar->height);
        emit videoResolutionChanged(m_videoResolution);
    }
    
    // 메타데이터에서 제목 추출
    AVDictionaryEntry* titleEntry = av_dict_get(m_formatContext->metadata, "title", nullptr, 0);
    if (titleEntry) {
        m_mediaTitle = QString(titleEntry->value);
        emit mediaTitleChanged(m_mediaTitle);
    }
}

void FFmpegEngine::updateTimecode()
{
    if (m_fps <= 0) return;
    
    int currentFrame = static_cast<int>(m_position * m_fps);
    m_timecode = TimecodeUtils::frameToTimecode(currentFrame, m_fps, 
                                               static_cast<TimecodeUtils::TimecodeFormat>(m_timecodeFormat));
}

void FFmpegEngine::handleVideoFrame(AVFrame* frame)
{
    QMutexLocker locker(&m_mutex);
    
    if (m_currentVideoFrame) {
        av_frame_free(&m_currentVideoFrame);
    }
    
    m_currentVideoFrame = av_frame_clone(frame);
    emit videoFrameReady(m_currentVideoFrame);
}

void FFmpegEngine::handleAudioFrame(AVFrame* frame)
{
    QMutexLocker locker(&m_mutex);
    
    if (m_currentAudioFrame) {
        av_frame_free(&m_currentAudioFrame);
    }
    
    m_currentAudioFrame = av_frame_clone(frame);
    emit audioFrameReady(m_currentAudioFrame);
}

void FFmpegEngine::handleEndOfStream()
{
    QMutexLocker locker(&m_mutex);
    
    m_isPlaying = false;
    m_positionTimer->stop();
    
    emit playingChanged(m_isPlaying);
    emit endReached();
    
    qDebug() << "End of stream reached";
}

void FFmpegEngine::onPositionTimer()
{
    // 실제 구현에서는 디코더로부터 현재 위치를 가져와야 함
    // 여기서는 간단한 시뮬레이션
    if (m_isPlaying && !m_isPaused) {
        m_position += 0.016; // 16ms 증가
        if (m_position >= m_duration) {
            m_position = m_duration;
            handleEndOfStream();
            return;
        }
        
        updateTimecode();
        emit positionChanged(m_position);
        emit timecodeChanged(m_timecode);
    }
}

AVFrame* FFmpegEngine::getCurrentVideoFrame()
{
    QMutexLocker locker(&m_mutex);
    return m_currentVideoFrame;
}

AVFrame* FFmpegEngine::getCurrentAudioFrame()
{
    QMutexLocker locker(&m_mutex);
    return m_currentAudioFrame;
}

void FFmpegEngine::setProperty(const QString& name, const QVariant& value)
{
    // 속성 설정 구현
    if (name == "timecode-format") {
        m_timecodeFormat = value.toInt();
        updateTimecode();
        emit timecodeChanged(m_timecode);
    }
    // 다른 속성들 추가 가능
}

QVariant FFmpegEngine::getProperty(const QString& name)
{
    // 속성 가져오기 구현
    if (name == "position") {
        return m_position;
    } else if (name == "duration") {
        return m_duration;
    } else if (name == "fps") {
        return m_fps;
    } else if (name == "frame-count") {
        return m_frameCount;
    } else if (name == "paused") {
        return m_isPaused;
    } else if (name == "playing") {
        return m_isPlaying;
    } else if (name == "timecode") {
        return m_timecode;
    }
    
    return QVariant();
} 