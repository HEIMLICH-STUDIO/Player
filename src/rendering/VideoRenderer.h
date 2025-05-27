#ifndef VIDEORENDERER_H
#define VIDEORENDERER_H

#include <QObject>
#include <QOpenGLWidget>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QOpenGLTexture>
#include <QOpenGLBuffer>
#include <QOpenGLVertexArrayObject>
#include <QMatrix4x4>
#include <QMutex>
#include <QSize>
#include <QtQuick/QQuickFramebufferObject>
#include <QOpenGLFramebufferObject>

extern "C" {
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
}

class FFmpegObject;

class VideoRenderer : public QOpenGLWidget, protected QOpenGLFunctions
{
    Q_OBJECT

public:
    explicit VideoRenderer(QWidget *parent = nullptr);
    ~VideoRenderer();

    // 프레임 렌더링
    void renderFrame(AVFrame* frame);
    void clearFrame();
    
    // 렌더링 설정
    void setAspectRatioMode(Qt::AspectRatioMode mode);
    Qt::AspectRatioMode aspectRatioMode() const { return m_aspectRatioMode; }
    
    void setRotation(int degrees);
    int rotation() const { return m_rotation; }
    
    void setFlipHorizontal(bool flip);
    bool isFlippedHorizontal() const { return m_flipHorizontal; }
    
    void setFlipVertical(bool flip);
    bool isFlippedVertical() const { return m_flipVertical; }
    
    // 색상 조정
    void setBrightness(float brightness);
    float brightness() const { return m_brightness; }
    
    void setContrast(float contrast);
    float contrast() const { return m_contrast; }
    
    void setSaturation(float saturation);
    float saturation() const { return m_saturation; }
    
    void setGamma(float gamma);
    float gamma() const { return m_gamma; }
    
    // 정보
    QSize frameSize() const { return m_frameSize; }
    QString pixelFormat() const { return m_pixelFormat; }

signals:
    void frameRendered();
    void renderingError(const QString& error);

protected:
    void initializeGL() override;
    void paintGL() override;
    void resizeGL(int width, int height) override;

private:
    void setupShaders();
    void setupGeometry();
    void updateTexture(AVFrame* frame);
    void convertToRGB(AVFrame* frame);
    void calculateViewport();
    QMatrix4x4 calculateTransformMatrix();
    
    // OpenGL 리소스
    QOpenGLShaderProgram* m_shaderProgram;
    QOpenGLTexture* m_textureY;
    QOpenGLTexture* m_textureU;
    QOpenGLTexture* m_textureV;
    QOpenGLBuffer m_vertexBuffer;
    QOpenGLVertexArrayObject m_vao;
    
    // 프레임 변환
    SwsContext* m_swsContext;
    AVFrame* m_rgbFrame;
    uint8_t* m_rgbBuffer;
    
    // 렌더링 상태
    QSize m_frameSize;
    QString m_pixelFormat;
    Qt::AspectRatioMode m_aspectRatioMode;
    int m_rotation;
    bool m_flipHorizontal;
    bool m_flipVertical;
    
    // 색상 조정
    float m_brightness;
    float m_contrast;
    float m_saturation;
    float m_gamma;
    
    // 뷰포트
    QRect m_viewport;
    QMatrix4x4 m_projectionMatrix;
    QMatrix4x4 m_modelMatrix;
    
    // 스레드 안전성
    mutable QMutex m_mutex;
    
    // 상수
    static constexpr int MAX_TEXTURE_SIZE = 4096;
};

// FFmpeg QML 렌더러
class FFmpegRenderer : public QQuickFramebufferObject::Renderer
{
public:
    explicit FFmpegRenderer(FFmpegObject* parent);
    ~FFmpegRenderer() override;

    void render() override;
    QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override;
    void synchronize(QQuickFramebufferObject* item) override;

private:
    FFmpegObject* m_parent;
    VideoRenderer* m_videoRenderer;
    QSize m_size;
};

#endif // VIDEORENDERER_H 