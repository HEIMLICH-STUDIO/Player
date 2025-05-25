#include "timelinesync.h"
#include <QRegularExpression>
#include <QRegularExpressionMatch>

TimelineSync::TimelineSync(QObject *parent)
    : QObject(parent)
{
    // 동기화 타이머 초기화 - 짧은 간격으로 정확한 동기화 유지
    m_syncTimer = new QTimer(this);
    m_syncTimer->setInterval(16);  // 약 60fps로 동기화 (16ms)
    connect(m_syncTimer, &QTimer::timeout, this, &TimelineSync::handleSyncTimer);
    

    
    // 시크 완료 타이머 - 시크 완료 후 상태 정리
    m_seekTimer = new QTimer(this);
    m_seekTimer->setSingleShot(true);
    m_seekTimer->setInterval(150);
    connect(m_seekTimer, &QTimer::timeout, this, &TimelineSync::completeSeek);
}

TimelineSync::~TimelineSync()
{
    // 연결 해제 및 리소스 정리
    if (m_mpv) {
        disconnect(m_mpv, nullptr, this, nullptr);
    }
}

// MPV 객체를 타임라인 동기화 클래스에 연결
void TimelineSync::connectMpv(MpvObject* mpv)
{
    if (!mpv) return;
    
    // 이전 연결 제거
    if (m_mpv) {
        disconnect(m_mpv, nullptr, this, nullptr);
    }
    
    m_mpv = mpv;
    
    // MPV 이벤트 연결
    connect(m_mpv, &MpvObject::positionChanged, this, &TimelineSync::onMpvPositionChanged);
    connect(m_mpv, &MpvObject::durationChanged, this, &TimelineSync::onMpvDurationChanged);
    connect(m_mpv, &MpvObject::playingChanged, this, &TimelineSync::onMpvPlayingChanged);
    connect(m_mpv, &MpvObject::pauseChanged, this, &TimelineSync::onMpvPauseChanged);
    connect(m_mpv, &MpvObject::endReached, this, &TimelineSync::onMpvEndReached);
    connect(m_mpv, &MpvObject::frameCountChanged, this, &TimelineSync::onMpvFrameCountChanged);
    
    // 초기 상태 업데이트
    m_position = m_mpv->position();
    m_duration = m_mpv->duration();
    m_isPlaying = !m_mpv->isPaused();
    
    // 프레임 레이트 가져오기 시도
    QVariant fpsVar = m_mpv->getProperty("estimated-vf-fps");
    if (fpsVar.isValid() && fpsVar.toDouble() > 0) {
        m_fps = fpsVar.toDouble();
        emit fpsChanged(m_fps);
    } else {
        // 기본값 사용
        m_fps = 24.0;
        emit fpsChanged(m_fps);
    }
    
    // 총 프레임 수 계산
    calculateTotalFrames();
    
    // 현재 프레임 업데이트
    updateFrameInfo();
    
    // 동기화 타이머 시작
    m_syncTimer->start();
}

// 특정 프레임으로 시크 - 시간 기반 변환 후 seekToPosition 호출
void TimelineSync::seekToFrame(int frame, bool exact)
{
    if (!m_mpv || m_duration <= 0) return;
    
    // 프레임 범위 검증
    frame = qBound(0, frame, m_totalFrames - 1);
    
    // 프레임을 시간 위치로 변환
    double targetPos = calculatePositionFromFrame(frame);
    
    // 시간 기반 시크 실행 (MPV 공식 권장 방식)
    seekToPosition(targetPos, exact);
}

// 특정 시간 위치로 시크 - MPV 공식 권장 시간 기반 방식
void TimelineSync::seekToPosition(double position, bool exact)
{
    if (!m_mpv || m_duration <= 0) return;
    
    // 위치 범위 검증
    position = qBound(0.0, position, m_duration - 0.1);
    
    // 시크 진행 중 플래그 설정
    m_seekInProgress = true;
    
    // 재생 중이면 일시 정지
    bool wasPlaying = m_isPlaying;
    if (wasPlaying) {
        m_mpv->pause();
    }
    
    // MPV 공식 권장 시간 기반 시크 직접 실행
    if (exact) {
        // 정확한 시간 위치 지정 (hr-seek 사용)
        m_mpv->command(QVariantList() << "seek" << position << "absolute" << "exact");
    } else {
        // 빠른 키프레임 시크
        m_mpv->command(QVariantList() << "seek" << position << "absolute" << "keyframes");
    }
    
    // 위치 정보 즉시 업데이트 (UI 반응성)
    m_position = position;
    emit positionChanged(m_position);
    
    // 해당 위치의 프레임 계산 및 업데이트
    if (m_fps > 0) {
        int frame = qRound(position * m_fps);
        frame = qBound(0, frame, m_totalFrames - 1);
        m_currentFrame = frame;
        emit currentFrameChanged(m_currentFrame);
    }
    
         // 시크 완료 타이머 시작
     m_seekTimer->start();
}

// 드래그 시작
void TimelineSync::beginDragging()
{
    m_isDragging = true;
    emit draggingChanged(m_isDragging);
    
    // 자동 동기화 일시 중지
    m_autoSync = false;
}

// 드래그 종료
void TimelineSync::endDragging()
{
    m_isDragging = false;
    emit draggingChanged(m_isDragging);
    
    // 마지막 프레임 위치 확인
    int currentFrame = m_currentFrame;
    
    // 정확한 프레임으로 시크
    seekToFrame(currentFrame, true);
    
    // 자동 동기화 재개
    m_autoSync = true;
}

// 정보 강제 업데이트
void TimelineSync::forceUpdate()
{
    if (!m_mpv) return;
    
    QMutexLocker locker(&m_syncMutex);
    
    // MPV에서 최신 정보 가져오기
    m_position = m_mpv->position();
    m_duration = m_mpv->duration();
    
    // FPS 업데이트
    QVariant fpsVar = m_mpv->getProperty("estimated-vf-fps");
    if (fpsVar.isValid() && fpsVar.toDouble() > 0) {
        m_fps = fpsVar.toDouble();
        emit fpsChanged(m_fps);
    }
    
    // 현재 프레임 및 총 프레임 수 계산
    calculateTotalFrames();
    updateFrameInfo();
    
    emit positionChanged(m_position);
    emit durationChanged(m_duration);
}

// 드래그 상태 설정
void TimelineSync::setIsDragging(bool dragging)
{
    if (m_isDragging != dragging) {
        m_isDragging = dragging;
        emit draggingChanged(m_isDragging);
        
        if (dragging) {
            beginDragging();
        } else {
            endDragging();
        }
    }
}

// MPV 위치 변경 처리
void TimelineSync::onMpvPositionChanged(double position)
{
    QMutexLocker locker(&m_syncMutex);
    
    // 드래그 중이거나 시크 진행 중이면 무시
    if (m_isDragging || !m_autoSync) return;
    
    if (std::abs(m_position - position) > 0.00001) {
        m_position = position;
        
        // 실시간으로 현재 프레임 업데이트
        updateFrameInfo();
        
        emit positionChanged(m_position);
    }
}

// MPV 영상 길이 변경 처리
void TimelineSync::onMpvDurationChanged(double duration)
{
    QMutexLocker locker(&m_syncMutex);
    
    if (m_duration != duration) {
        m_duration = duration;
        calculateTotalFrames();
        emit durationChanged(m_duration);
    }
}

// MPV 재생 상태 변경 처리
void TimelineSync::onMpvPlayingChanged(bool playing)
{
    QMutexLocker locker(&m_syncMutex);
    
    if (m_isPlaying != playing) {
        m_isPlaying = playing;
        emit playingStateChanged(m_isPlaying);
    }
}

// MPV 일시정지 상태 변경 처리
void TimelineSync::onMpvPauseChanged(bool paused)
{
    QMutexLocker locker(&m_syncMutex);
    
    bool playing = !paused;
    if (m_isPlaying != playing) {
        m_isPlaying = playing;
        emit playingStateChanged(m_isPlaying);
    }
}

// 동기화 타이머 핸들러 - 재생 중 실시간 동기화
void TimelineSync::handleSyncTimer()
{
    if (!m_mpv || m_isDragging || m_seekInProgress) return;
    
    QMutexLocker locker(&m_syncMutex);
    
    try {
        // 현재 위치 가져오기
        QVariant posVar = m_mpv->getProperty("time-pos");
        if (!posVar.isValid()) return;
        
        double newPos = posVar.toDouble();
        
        // 위치가 변경된 경우만 업데이트
        if (std::abs(newPos - m_position) > 0.01) {
            m_position = newPos;
            
            // 현재 프레임 계산하여 업데이트
            int newFrame = calculateFrameFromPosition(newPos);
            if (newFrame != m_currentFrame) {
                m_currentFrame = newFrame;
                emit currentFrameChanged(m_currentFrame);
            }
            
            emit positionChanged(m_position);
        }
        
        // 재생 상태 확인
        QVariant pauseVar = m_mpv->getProperty("pause");
        if (pauseVar.isValid()) {
            bool isPaused = pauseVar.toBool();
            bool newPlayingState = !isPaused;
            
            if (m_isPlaying != newPlayingState) {
                m_isPlaying = newPlayingState;
                emit playingStateChanged(m_isPlaying);
            }
        }
        
        // 정기적으로 총 프레임 수 확인 (동영상이 로드된 경우)
        static int frameCountCheck = 0;
        if (++frameCountCheck % 60 == 0 && m_mpv->duration() > 0) {
            calculateTotalFrames();
            frameCountCheck = 0;
        }
    } catch (...) {
        qWarning() << "Error in sync timer handler";
    }
}



// 시크 완료 처리
void TimelineSync::completeSeek()
{
    QMutexLocker locker(&m_syncMutex);
    
    // 최종 위치 확인
    if (m_mpv) {
        QVariant posVar = m_mpv->getProperty("time-pos");
        if (posVar.isValid()) {
            double finalPos = posVar.toDouble();
            m_position = finalPos;
            
            // 최종 프레임 계산
            int finalFrame = calculateFrameFromPosition(finalPos);
            if (finalFrame != m_currentFrame) {
                m_currentFrame = finalFrame;
                emit currentFrameChanged(m_currentFrame);
            }
            
            emit positionChanged(m_position);
        }
    }
    
    // 시크 완료 표시
    m_seekInProgress = false;
    m_updatePending = false;
    
    emit seekCompleted();
}

// 프레임 정보 업데이트
void TimelineSync::updateFrameInfo()
{
    if (m_duration <= 0 || m_fps <= 0) return;
    
    // 현재 프레임 계산
    int newFrame = calculateFrameFromPosition(m_position);
    
    // 프레임이 변경되었으면 신호 발생
    if (m_currentFrame != newFrame) {
        m_currentFrame = newFrame;
        emit currentFrameChanged(m_currentFrame);
    }
}

// 총 프레임 수 계산 - MPV 네이티브 값 우선 사용
void TimelineSync::calculateTotalFrames()
{
    if (!m_mpv || m_duration <= 0 || m_fps <= 0) return;
    
    int frames = 0;
    
    // 1. MPV의 실제 프레임 카운트 사용 (최우선)
    QVariant frameCountVar = m_mpv->getProperty("estimated-frame-count");
    if (frameCountVar.isValid() && frameCountVar.toInt() > 0) {
        frames = frameCountVar.toInt();
        qDebug() << "TimelineSync: Using MPV estimated-frame-count:" << frames;
    } else {
        // 2. MPV 객체의 frameCount() 메서드 사용
        frames = m_mpv->frameCount();
        if (frames > 0) {
            qDebug() << "TimelineSync: Using MPV frameCount():" << frames;
        } else {
            // 3. 계산 방식 (fallback)
            frames = std::ceil(m_duration * m_fps);
            qDebug() << "TimelineSync: Using calculated frames:" << frames;
        }
    }
    
    // 변경되었으면 신호 발생
    if (m_totalFrames != frames) {
        m_totalFrames = frames;
        emit totalFramesChanged(m_totalFrames);
        qDebug() << "TimelineSync: Total frames updated to:" << m_totalFrames;
    }
}

// 시간 위치에서 프레임 번호 계산
int TimelineSync::calculateFrameFromPosition(double pos) const
{
    if (m_fps <= 0) return 0;
    
    return qBound(0, qRound(pos * m_fps), m_totalFrames - 1);
}

// 프레임 번호에서 시간 위치 계산
double TimelineSync::calculatePositionFromFrame(int frame) const
{
    if (m_fps <= 0) return 0.0;
    
    return frame / m_fps;
}

// 프레임을 타임코드 문자열로 변환 (HH:MM:SS:FF)
QString TimelineSync::frameToTimecode(int frame) const
{
    if (m_fps <= 0) return "00:00:00:00";
    
    // 프레임을 초로 변환
    double seconds = frame / m_fps;
    
    // 시, 분, 초, 프레임 계산
    int hours = int(seconds / 3600);
    int minutes = int((seconds - hours * 3600) / 60);
    int secs = int(seconds) % 60;
    int frames = int(frame % int(m_fps));
    
    // 타임코드 형식으로 조합
    return QString("%1:%2:%3:%4")
            .arg(hours, 2, 10, QChar('0'))
            .arg(minutes, 2, 10, QChar('0'))
            .arg(secs, 2, 10, QChar('0'))
            .arg(frames, 2, 10, QChar('0'));
}

// 타임코드 문자열을 프레임 번호로 변환
int TimelineSync::timecodeToFrame(const QString& timecode) const
{
    if (m_fps <= 0) return 0;
    
    // 타임코드 형식 확인 (HH:MM:SS:FF)
    QRegularExpression regex("(\\d{2}):(\\d{2}):(\\d{2}):(\\d{2})");
    QRegularExpressionMatch match = regex.match(timecode);
    
    if (!match.hasMatch())
        return 0;
    
    // 각 부분 추출
    int hours = match.captured(1).toInt();
    int minutes = match.captured(2).toInt();
    int seconds = match.captured(3).toInt();
    int frames = match.captured(4).toInt();
    
    // 프레임 계산
    int totalSeconds = hours * 3600 + minutes * 60 + seconds;
    int totalFrames = totalSeconds * m_fps + frames;
    
    return qBound(0, totalFrames, m_totalFrames - 1);
}

// 프레임을 시간 위치로 변환
double TimelineSync::frameToPosition(int frame) const
{
    return calculatePositionFromFrame(frame);
}

// 시간 위치를 프레임으로 변환
int TimelineSync::positionToFrame(double position) const
{
    return calculateFrameFromPosition(position);
}

// MPV EOF 이벤트 핸들러
void TimelineSync::onMpvEndReached()
{
    QMutexLocker locker(&m_syncMutex);
    
    qDebug() << "TimelineSync: EOF reached, handling end of video";
    
    // 재생 중지
    m_isPlaying = false;
    emit playingStateChanged(m_isPlaying);
    
    // 안전한 마지막 프레임으로 이동 (마지막에서 2-3프레임 앞)
    if (m_totalFrames > 3) {
        int safeEndFrame = m_totalFrames - 3;
        m_currentFrame = safeEndFrame;
        emit currentFrameChanged(m_currentFrame);
        
        // 위치도 업데이트
        m_position = calculatePositionFromFrame(safeEndFrame);
        emit positionChanged(m_position);
        
        qDebug() << "TimelineSync: Moved to safe end frame:" << safeEndFrame;
    }
    
    // EOF 신호 발생
    emit seekCompleted();
}

// MPV 프레임 카운트 변경 핸들러
void TimelineSync::onMpvFrameCountChanged(int frameCount)
{
    QMutexLocker locker(&m_syncMutex);
    
    if (m_totalFrames != frameCount && frameCount > 0) {
        qDebug() << "TimelineSync: Frame count updated from MPV:" << frameCount;
        m_totalFrames = frameCount;
        emit totalFramesChanged(m_totalFrames);
        
        // 현재 프레임이 범위를 벗어났으면 조정
        if (m_currentFrame >= m_totalFrames) {
            m_currentFrame = m_totalFrames - 1;
            emit currentFrameChanged(m_currentFrame);
        }
    }
} 