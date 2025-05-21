#ifndef TIMELINESYNC_H
#define TIMELINESYNC_H

#include <QObject>
#include <QTimer>
#include <QMutex>
#include <QDebug>
#include <cmath>
#include "mpvobject.h"

// 타임라인과 비디오 동기화를 정밀하게 관리하는 클래스
class TimelineSync : public QObject
{
    Q_OBJECT
    
    // QML에 노출될 속성들
    Q_PROPERTY(int currentFrame READ currentFrame NOTIFY currentFrameChanged)
    Q_PROPERTY(int totalFrames READ totalFrames NOTIFY totalFramesChanged)
    Q_PROPERTY(double fps READ fps NOTIFY fpsChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playingStateChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool isDragging READ isDragging WRITE setIsDragging NOTIFY draggingChanged)
    
public:
    explicit TimelineSync(QObject *parent = nullptr);
    ~TimelineSync();
    
    // MPV 객체 연결
    void connectMpv(MpvObject* mpv);
    
    // QML에서 호출 가능한 메서드들
    Q_INVOKABLE void seekToFrame(int frame, bool exact = true);
    Q_INVOKABLE void seekToPosition(double position, bool exact = true);
    Q_INVOKABLE void beginDragging();
    Q_INVOKABLE void endDragging();
    Q_INVOKABLE void forceUpdate();
    Q_INVOKABLE void stepFrames(int frames);
    
    // 속성 접근자
    int currentFrame() const { return m_currentFrame; }
    int totalFrames() const { return m_totalFrames; }
    double fps() const { return m_fps; }
    bool isPlaying() const { return m_isPlaying; }
    double position() const { return m_position; }
    double duration() const { return m_duration; }
    bool isDragging() const { return m_isDragging; }
    
    // 타임코드 변환 유틸리티
    Q_INVOKABLE QString frameToTimecode(int frame) const;
    Q_INVOKABLE int timecodeToFrame(const QString& timecode) const;
    Q_INVOKABLE double frameToPosition(int frame) const;
    Q_INVOKABLE int positionToFrame(double position) const;
    
    // 속성 설정자
    void setIsDragging(bool dragging);
    
signals:
    // 속성 변경 신호
    void currentFrameChanged(int frame);
    void totalFramesChanged(int frames);
    void fpsChanged(double fps);
    void playingStateChanged(bool playing);
    void positionChanged(double position);
    void durationChanged(double duration);
    void draggingChanged(bool dragging);
    
    // 동기화 이벤트 신호
    void syncRequested();
    void seekCompleted();
    
private slots:
    // MPV 이벤트 핸들러
    void onMpvPositionChanged(double position);
    void onMpvDurationChanged(double duration);
    void onMpvPlayingChanged(bool playing);
    void onMpvPauseChanged(bool paused);
    
    // 내부 동기화 핸들러
    void handleSyncTimer();
    void handleVerificationTimer();
    void completeSeek();
    
private:
    // 프레임 계산 유틸리티
    void updateFrameInfo();
    void calculateTotalFrames();
    int calculateFrameFromPosition(double pos) const;
    double calculatePositionFromFrame(int frame) const;
    
    // 멤버 변수
    MpvObject* m_mpv = nullptr;
    
    // 재생 상태
    int m_currentFrame = 0;
    int m_totalFrames = 0;
    double m_fps = 24.0;
    bool m_isPlaying = false;
    double m_position = 0.0;
    double m_duration = 0.0;
    bool m_isDragging = false;
    bool m_seekInProgress = false;
    
    // 동기화 타이머
    QTimer* m_syncTimer = nullptr;
    QTimer* m_verifyTimer = nullptr;
    QTimer* m_seekTimer = nullptr;
    
    // 스레드 안전성을 위한 뮤텍스
    QMutex m_syncMutex;
    
    // 내부 상태 플래그
    bool m_updatePending = false;
    bool m_autoSync = true;
};

#endif // TIMELINESYNC_H 