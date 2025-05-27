#ifndef VIDEOSCOPERENDERER_H
#define VIDEOSCOPERENDERER_H

#include <QQuickFramebufferObject>
#include <QQuickItem>
#include <QMutex>
#include <QTimerEvent>
#include <QDateTime>
#include <QVariant>
#include <QDebug>
#include <cmath>
#include "FFmpegObject.h"

enum class ScopeType {
    Waveform = 0,
    Vectorscope = 1,
    Histogram = 2,
    RGB_Parade = 3
};

class VideoScopeItem : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(QVariant ffmpegObject READ ffmpegObject WRITE setFfmpegObject NOTIFY ffmpegObjectChanged)
    Q_PROPERTY(int scopeType READ scopeType WRITE setScopeType NOTIFY scopeTypeChanged)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int intensity READ intensity WRITE setIntensity NOTIFY intensityChanged)
    Q_PROPERTY(bool logarithmic READ logarithmic WRITE setLogarithmic NOTIFY logarithmicChanged)
    Q_PROPERTY(int mode READ mode WRITE setMode NOTIFY modeChanged)
    
public:
    VideoScopeItem(QQuickItem* parent = nullptr);
    ~VideoScopeItem();
    
    QQuickFramebufferObject::Renderer* createRenderer() const override;
    
    QVariant ffmpegObject() const { return m_ffmpegObject; }
    void setFfmpegObject(const QVariant& obj);
    
    int scopeType() const { return static_cast<int>(m_scopeType); }
    void setScopeType(int type);
    
    bool isActive() const { return m_active; }
    void setActive(bool active);
    
    int intensity() const { return m_intensity; }
    void setIntensity(int intensity);
    
    bool logarithmic() const { return m_logarithmic; }
    void setLogarithmic(bool logarithmic);
    
    int mode() const { return m_mode; }
    void setMode(int mode);
    
    // FFmpeg 핸들 관련 메서드는 제거됨
    
public slots:
    void updateFrameData();
    void handleFrameSwap();
    void handleFfmpegEvents();
    
signals:
    void ffmpegObjectChanged();
    void scopeTypeChanged();
    void activeChanged();
    void intensityChanged();
    void logarithmicChanged();
    void modeChanged();
    
protected:
    void timerEvent(QTimerEvent* event) override;
    
private:
    bool extractCurrentFrame();
    void HSVtoRGB(float h, float s, float v, float &r, float &g, float &b);
    
    QVariant m_ffmpegObject;
    FFmpegObject* m_ffmpeg;
    ScopeType m_scopeType;
    bool m_active;
    int m_intensity;
    bool m_logarithmic;
    int m_mode;
    
    // 프레임 데이터
    QMutex m_frameMutex;
    unsigned char* m_frameData;
    int m_dataWidth;
    int m_dataHeight;
    
    friend class VideoScopeRenderer;
};

class VideoScopeRenderer : public QQuickFramebufferObject::Renderer
{
public:
    VideoScopeRenderer();
    ~VideoScopeRenderer();
    
    void render() override;
    QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override;
    
private:
    VideoScopeItem* m_item;
};

#endif // VIDEOSCOPERENDERER_H 