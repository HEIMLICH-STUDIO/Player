#include "FFmpegObject.h"
#include "rendering/VideoRenderer.h"
#include "utils/TimecodeUtils.h"
#include <QDebug>
#include <QTimer>
#include <QUrl>

FFmpegObject::FFmpegObject(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
    , m_engine(new FFmpegEngine(this))
{
    // 타이머 초기화
    m_stateChangeTimer = new QTimer(this);
    m_stateChangeTimer->setSingleShot(true);
    m_stateChangeTimer->setInterval(100);
    connect(m_stateChangeTimer, &QTimer::timeout, this, &FFmpegObject::processStateChange);
    
    m_performanceTimer = new QTimer(this);
    m_performanceTimer->setInterval(5000); // 5초마다 성능 체크
    connect(m_performanceTimer, &QTimer::timeout, this, &FFmpegObject::checkPerformance);
    
    m_metadataTimer = new QTimer(this);
    m_metadataTimer->setSingleShot(true);
    m_metadataTimer->setInterval(500);
    connect(m_metadataTimer, &QTimer::timeout, this, &FFmpegObject::updateVideoMetadata);
    
    m_timecodeTimer = new QTimer(this);
    m_timecodeTimer->setInterval(33); // ~30fps
    connect(m_timecodeTimer, &QTimer::timeout, this, &FFmpegObject::updateTimecode);
    
    // 엔진 신호 연결
    connectEngineSignals();
    
    qDebug() << "FFmpegObject created";
}

FFmpegObject::~FFmpegObject()
{
    qDebug() << "FFmpegObject destroyed";
}

QQuickFramebufferObject::Renderer* FFmpegObject::createRenderer() const
{
    return new FFmpegRenderer(const_cast<FFmpegObject*>(this));
}

void FFmpegObject::connectEngineSignals()
{
    connect(m_engine, &FFmpegEngine::filenameChanged, this, &FFmpegObject::onEngineFilenameChanged);
    connect(m_engine, &FFmpegEngine::positionChanged, this, &FFmpegObject::onEnginePositionChanged);
    connect(m_engine, &FFmpegEngine::durationChanged, this, &FFmpegObject::onEngineDurationChanged);
    connect(m_engine, &FFmpegEngine::fpsChanged, this, &FFmpegObject::onEngineFpsChanged);
    connect(m_engine, &FFmpegEngine::frameCountChanged, this, &FFmpegObject::onEngineFrameCountChanged);
    connect(m_engine, &FFmpegEngine::playingChanged, this, &FFmpegObject::onEnginePlayingChanged);
    connect(m_engine, &FFmpegEngine::pauseChanged, this, &FFmpegObject::onEnginePauseChanged);
    connect(m_engine, &FFmpegEngine::videoCodecChanged, this, &FFmpegObject::onEngineVideoCodecChanged);
    connect(m_engine, &FFmpegEngine::videoFormatChanged, this, &FFmpegObject::onEngineVideoFormatChanged);
    connect(m_engine, &FFmpegEngine::videoResolutionChanged, this, &FFmpegObject::onEngineVideoResolutionChanged);
    connect(m_engine, &FFmpegEngine::mediaTitleChanged, this, &FFmpegObject::onEngineMediaTitleChanged);
    connect(m_engine, &FFmpegEngine::timecodeChanged, this, &FFmpegObject::onEngineTimecodeChanged);
    connect(m_engine, &FFmpegEngine::endReached, this, &FFmpegObject::onEngineEndReached);
    connect(m_engine, &FFmpegEngine::error, this, &FFmpegObject::onEngineError);
    
    connect(m_engine, &FFmpegEngine::videoFrameReady, this, [this](AVFrame* frame) {
        // 렌더러에게 새 프레임 알림
        update();
    });
}

// MPV 호환 접근자들
QString FFmpegObject::filename() const
{
    return m_filename;
}

bool FFmpegObject::isPaused() const
{
    return m_pause;
}

double FFmpegObject::position() const
{
    return m_position;
}

double FFmpegObject::duration() const
{
    return m_duration;
}

double FFmpegObject::fps() const
{
    return m_fps;
}

QString FFmpegObject::mediaTitle() const
{
    return m_mediaTitle;
}

bool FFmpegObject::isEndReached() const
{
    return m_endReached;
}

bool FFmpegObject::isLoopEnabled() const
{
    return m_loopEnabled;
}

void FFmpegObject::setLoopEnabled(bool enabled)
{
    if (m_loopEnabled != enabled) {
        m_loopEnabled = enabled;
        emit loopChanged(enabled);
    }
}

int FFmpegObject::frameCount() const
{
    return m_frameCount;
}

bool FFmpegObject::isOneBasedFrameNumbers() const
{
    return m_oneBasedFrameNumbers;
}

void FFmpegObject::setOneBasedFrameNumbers(bool oneBased)
{
    if (m_oneBasedFrameNumbers != oneBased) {
        m_oneBasedFrameNumbers = oneBased;
        emit oneBasedFrameNumbersChanged(oneBased);
    }
}

bool FFmpegObject::isKeepOpenEnabled() const
{
    return m_keepOpenEnabled;
}

void FFmpegObject::setKeepOpenEnabled(bool enabled)
{
    if (m_keepOpenEnabled != enabled) {
        m_keepOpenEnabled = enabled;
        emit keepOpenChanged(enabled);
    }
}

// 코덱 정보 접근자들
QString FFmpegObject::videoCodec() const
{
    return m_videoCodec;
}

QString FFmpegObject::videoFormat() const
{
    return m_videoFormat;
}

QString FFmpegObject::videoResolution() const
{
    return m_videoResolution;
}

// 타임코드 관련 접근자들
QString FFmpegObject::timecode() const
{
    return m_timecode;
}

int FFmpegObject::timecodeFormat() const
{
    return m_timecodeFormat;
}

void FFmpegObject::setTimecodeFormat(int format)
{
    if (m_timecodeFormat != format) {
        m_timecodeFormat = format;
        m_engine->setTimecodeFormat(format);
        emit timecodeFormatChanged(format);
        updateTimecode();
    }
}

bool FFmpegObject::useEmbeddedTimecode() const
{
    return m_useEmbeddedTimecode;
}

void FFmpegObject::setUseEmbeddedTimecode(bool use)
{
    if (m_useEmbeddedTimecode != use) {
        m_useEmbeddedTimecode = use;
        emit useEmbeddedTimecodeChanged(use);
        if (use) {
            fetchEmbeddedTimecode();
        }
    }
}

QString FFmpegObject::embeddedTimecode() const
{
    return m_embeddedTimecode;
}

int FFmpegObject::timecodeOffset() const
{
    return m_timecodeOffset;
}

void FFmpegObject::setTimecodeOffset(int offset)
{
    if (m_timecodeOffset != offset) {
        m_timecodeOffset = offset;
        emit timecodeOffsetChanged(offset);
        updateTimecode();
    }
}

QString FFmpegObject::customTimecodePattern() const
{
    return m_customTimecodePattern;
}

void FFmpegObject::setCustomTimecodePattern(const QString& pattern)
{
    if (m_customTimecodePattern != pattern) {
        m_customTimecodePattern = pattern;
        emit customTimecodePatternChanged(pattern);
        updateTimecode();
    }
}

int FFmpegObject::timecodeSource() const
{
    return m_timecodeSource;
}

void FFmpegObject::setTimecodeSource(int source)
{
    if (m_timecodeSource != source) {
        m_timecodeSource = source;
        emit timecodeSourceChanged(source);
        updateTimecode();
    }
}

// 타임코드 유틸리티 메서드들
QString FFmpegObject::frameToTimecode(int frame, int format, const QString& customPattern) const
{
    if (m_fps <= 0) return "00:00:00:00";
    
    TimecodeUtils::TimecodeFormat tcFormat = static_cast<TimecodeUtils::TimecodeFormat>(
        format >= 0 ? format : m_timecodeFormat);
    
    if (tcFormat == TimecodeUtils::CUSTOM && !customPattern.isEmpty()) {
        return TimecodeUtils::frameToCustom(frame, m_fps, customPattern);
    }
    
    return TimecodeUtils::frameToTimecode(frame, m_fps, tcFormat);
}

int FFmpegObject::timecodeToFrame(const QString& tc) const
{
    if (m_fps <= 0) return 0;
    
    TimecodeUtils::TimecodeFormat tcFormat = static_cast<TimecodeUtils::TimecodeFormat>(m_timecodeFormat);
    return TimecodeUtils::timecodeToFrame(tc, m_fps, tcFormat);
}

// 프레임 번호 변환 함수들
int FFmpegObject::displayFrameNumber(int internalFrame) const
{
    return m_oneBasedFrameNumbers ? internalFrame + 1 : internalFrame;
}

int FFmpegObject::internalFrameNumber(int displayFrame) const
{
    return m_oneBasedFrameNumbers ? displayFrame - 1 : displayFrame;
}

// MPV 호환 제어 메서드들
void FFmpegObject::play()
{
    if (m_endReached && m_loopEnabled) {
        seekToPosition(0.0);
        resetEndReached();
    }
    
    m_engine->play();
    m_timecodeTimer->start();
}

void FFmpegObject::pause()
{
    m_engine->pause();
    if (m_engine->isPaused()) {
        m_timecodeTimer->stop();
    } else {
        m_timecodeTimer->start();
    }
}

void FFmpegObject::playPause()
{
    if (m_pause) {
        play();
    } else {
        pause();
    }
}

void FFmpegObject::command(const QVariant& params)
{
    // MPV 호환 명령 처리
    QVariantList paramList = params.toList();
    if (paramList.isEmpty()) return;
    
    QString cmd = paramList[0].toString();
    
    if (cmd == "loadfile" && paramList.size() > 1) {
        QString filename = paramList[1].toString();
        
        // URL 처리
        if (filename.startsWith("file://")) {
            QUrl url(filename);
            filename = url.toLocalFile();
        }
        
        if (m_engine->openFile(filename)) {
            m_metadataTimer->start();
            emit fileLoaded();
        }
    } else if (cmd == "seek" && paramList.size() > 1) {
        double pos = paramList[1].toDouble();
        seekToPosition(pos);
    } else if (cmd == "frame-step") {
        // 다음 프레임으로 이동
        if (m_fps > 0) {
            double nextPos = m_position + (1.0 / m_fps);
            seekToPosition(nextPos);
        }
    } else if (cmd == "frame-back-step") {
        // 이전 프레임으로 이동
        if (m_fps > 0) {
            double prevPos = m_position - (1.0 / m_fps);
            seekToPosition(qMax(0.0, prevPos));
        }
    }
}

void FFmpegObject::setProperty(const QString& name, const QVariant& value)
{
    m_engine->setProperty(name, value);
}

QVariant FFmpegObject::getProperty(const QString& name)
{
    return m_engine->getProperty(name);
}

void FFmpegObject::handleFFmpegEvents()
{
    // FFmpeg 이벤트 처리 (필요한 경우)
}

void FFmpegObject::updatePositionProperty()
{
    // 포지션 업데이트 처리
}

void FFmpegObject::processStateChange()
{
    // 상태 변경 처리
}

void FFmpegObject::checkPerformance()
{
    // 성능 모니터링
    QDateTime now = QDateTime::currentDateTime();
    if (m_lastPerformanceCheck.isValid()) {
        qint64 elapsed = m_lastPerformanceCheck.msecsTo(now);
        if (elapsed > 10000 && !m_performanceOptimizationApplied) {
            // 10초 이상 경과 시 성능 최적화 적용
            m_performanceOptimizationApplied = true;
            qDebug() << "Applying performance optimizations";
        }
    }
    m_lastPerformanceCheck = now;
}

void FFmpegObject::resetEndReached()
{
    if (m_endReached) {
        m_endReached = false;
        emit endReachedChanged(false);
    }
}

void FFmpegObject::handleEndOfVideo()
{
    if (m_loopEnabled) {
        seekToPosition(0.0);
        resetEndReached();
    } else {
        m_endReached = true;
        emit endReached();
        emit endReachedChanged(true);
    }
}

void FFmpegObject::seekToPosition(double pos)
{
    m_lastSeekTime = QDateTime::currentMSecsSinceEpoch();
    m_engine->seekToPosition(pos);
}

void FFmpegObject::updateFrameCount()
{
    // 프레임 수 업데이트 처리
}

void FFmpegObject::updateVideoMetadata()
{
    emit videoMetadataChanged();
}

void FFmpegObject::applyVideoFilters(const QStringList& filters)
{
    // 비디오 필터 적용 (향후 구현)
    Q_UNUSED(filters)
}

void FFmpegObject::updateTimecode()
{
    updateTimecodeFromPosition();
}

void FFmpegObject::fetchEmbeddedTimecode()
{
    // 내장 타임코드 추출 (향후 구현)
    AVFrame* currentFrame = m_engine->getCurrentVideoFrame();
    if (currentFrame && TimecodeUtils::hasEmbeddedTimecode(currentFrame)) {
        QString embedded = TimecodeUtils::extractEmbeddedTimecode(currentFrame);
        if (m_embeddedTimecode != embedded) {
            m_embeddedTimecode = embedded;
            emit embeddedTimecodeChanged(embedded);
        }
    }
}

void FFmpegObject::seekToLastFrame()
{
    if (m_frameCount > 0) {
        int lastFrame = m_frameCount - 1;
        m_engine->seekToFrame(lastFrame);
    }
}

void FFmpegObject::seekToFirstFrame()
{
    m_engine->seekToFrame(0);
}

// 엔진 신호 핸들러들
void FFmpegObject::onEngineFilenameChanged(const QString& filename)
{
    if (m_filename != filename) {
        m_filename = filename;
        emit filenameChanged(filename);
    }
}

void FFmpegObject::onEnginePositionChanged(double position)
{
    if (qAbs(m_position - position) > 0.001) { // 1ms 이상 차이날 때만 업데이트
        m_lastPosition = m_position;
        m_position = position;
        emit positionChanged(position);
        updateTimecodeFromPosition();
    }
}

void FFmpegObject::onEngineDurationChanged(double duration)
{
    if (qAbs(m_duration - duration) > 0.001) {
        m_duration = duration;
        emit durationChanged(duration);
    }
}

void FFmpegObject::onEngineFpsChanged(double fps)
{
    if (qAbs(m_fps - fps) > 0.001) {
        m_fps = fps;
        emit fpsChanged(fps);
    }
}

void FFmpegObject::onEngineFrameCountChanged(int count)
{
    if (m_frameCount != count) {
        m_frameCount = count;
        emit frameCountChanged(count);
    }
}

void FFmpegObject::onEnginePlayingChanged(bool playing)
{
    emit playingChanged(playing);
}

void FFmpegObject::onEnginePauseChanged(bool paused)
{
    if (m_pause != paused) {
        m_pause = paused;
        emit pauseChanged(paused);
    }
}

void FFmpegObject::onEngineVideoCodecChanged(const QString& codec)
{
    if (m_videoCodec != codec) {
        m_videoCodec = codec;
        emit videoCodecChanged(codec);
    }
}

void FFmpegObject::onEngineVideoFormatChanged(const QString& format)
{
    if (m_videoFormat != format) {
        m_videoFormat = format;
        emit videoFormatChanged(format);
    }
}

void FFmpegObject::onEngineVideoResolutionChanged(const QString& resolution)
{
    if (m_videoResolution != resolution) {
        m_videoResolution = resolution;
        emit videoResolutionChanged(resolution);
    }
}

void FFmpegObject::onEngineMediaTitleChanged(const QString& title)
{
    if (m_mediaTitle != title) {
        m_mediaTitle = title;
        emit mediaTitleChanged(title);
    }
}

void FFmpegObject::onEngineTimecodeChanged(const QString& timecode)
{
    if (m_timecode != timecode) {
        m_timecode = timecode;
        emit timecodeChanged(timecode);
    }
}

void FFmpegObject::onEngineEndReached()
{
    handleEndOfVideo();
}

void FFmpegObject::onEngineError(const QString& message)
{
    qDebug() << "FFmpeg engine error:" << message;
}

void FFmpegObject::updateTimecodeFromPosition()
{
    if (m_fps > 0) {
        calculateTimecode();
    }
}

void FFmpegObject::calculateTimecode()
{
    if (m_fps <= 0) return;
    
    int currentFrame = static_cast<int>(m_position * m_fps) + m_timecodeOffset;
    
    QString newTimecode;
    
    if (m_useEmbeddedTimecode && !m_embeddedTimecode.isEmpty()) {
        newTimecode = m_embeddedTimecode;
    } else {
        TimecodeUtils::TimecodeFormat format = static_cast<TimecodeUtils::TimecodeFormat>(m_timecodeFormat);
        
        if (format == TimecodeUtils::CUSTOM) {
            newTimecode = TimecodeUtils::frameToCustom(currentFrame, m_fps, m_customTimecodePattern);
        } else {
            newTimecode = TimecodeUtils::frameToTimecode(currentFrame, m_fps, format);
        }
    }
    
    if (m_timecode != newTimecode) {
        m_timecode = newTimecode;
        emit timecodeChanged(newTimecode);
    }
} 