#include "../FFmpegObject.h"
#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QOpenGLExtraFunctions>
#include <QDebug>
#include <QElapsedTimer>
#include <cmath>

// Static shader sources with modern GLSL
const QString VideoRenderer::s_vertexShaderSource = R"(
#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texCoord;

uniform mat4 mvpMatrix;

out vec2 TexCoord;

void main()
{
    gl_Position = mvpMatrix * vec4(position, 1.0);
    TexCoord = texCoord;
}
)";

const QString VideoRenderer::s_fragmentShaderYUV420P = R"(
#version 330 core

in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D textureY;
uniform sampler2D textureU;
uniform sampler2D textureV;
uniform int colorSpace;
uniform float brightness;
uniform float contrast;
uniform float saturation;
uniform float gamma;
uniform bool hdrEnabled;

// Color space conversion matrices
const mat3 BT601 = mat3(
    1.164,  1.164,  1.164,
    0.000, -0.392,  2.017,
    1.596, -0.813,  0.000
);

const mat3 BT709 = mat3(
    1.164,  1.164,  1.164,
    0.000, -0.213,  2.112,
    1.793, -0.533,  0.000
);

const mat3 BT2020 = mat3(
    1.164,  1.164,  1.164,
    0.000, -0.187,  2.148,
    1.717, -0.652,  0.000
);

vec3 yuv2rgb(vec3 yuv, mat3 matrix) {
    yuv.x = yuv.x - 0.0625;  // Y offset
    yuv.y = yuv.y - 0.5;     // U offset
    yuv.z = yuv.z - 0.5;     // V offset
    return matrix * yuv;
}

vec3 adjustColor(vec3 color) {
    // Brightness
    color += brightness;
    
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    
    // Saturation
    vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    color = mix(gray, color, saturation);
    
    // Gamma correction
    color = pow(max(color, 0.0), vec3(1.0 / gamma));
    
    return color;
}

vec3 toneMapping(vec3 color) {
    if (!hdrEnabled) return color;
    
    // Simple Reinhard tone mapping
    return color / (color + vec3(1.0));
}

void main()
{
    float y = texture(textureY, TexCoord).r;
    float u = texture(textureU, TexCoord).r;
    float v = texture(textureV, TexCoord).r;
    
    vec3 yuv = vec3(y, u, v);
    vec3 rgb;
    
    if (colorSpace == 1) {
        rgb = yuv2rgb(yuv, BT601);
    } else if (colorSpace == 2) {
        rgb = yuv2rgb(yuv, BT709);
    } else if (colorSpace == 3) {
        rgb = yuv2rgb(yuv, BT2020);
    } else {
        rgb = yuv2rgb(yuv, BT709); // Default
    }
    
    rgb = adjustColor(rgb);
    rgb = toneMapping(rgb);
    
    FragColor = vec4(clamp(rgb, 0.0, 1.0), 1.0);
}
)";

const QString VideoRenderer::s_fragmentShaderNV12 = R"(
#version 330 core

in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D textureY;
uniform sampler2D textureUV;
uniform int colorSpace;
uniform float brightness;
uniform float contrast;
uniform float saturation;
uniform float gamma;
uniform bool hdrEnabled;

// Same matrices and functions as YUV420P shader
const mat3 BT601 = mat3(
    1.164,  1.164,  1.164,
    0.000, -0.392,  2.017,
    1.596, -0.813,  0.000
);

const mat3 BT709 = mat3(
    1.164,  1.164,  1.164,
    0.000, -0.213,  2.112,
    1.793, -0.533,  0.000
);

const mat3 BT2020 = mat3(
    1.164,  1.164,  1.164,
    0.000, -0.187,  2.148,
    1.717, -0.652,  0.000
);

vec3 yuv2rgb(vec3 yuv, mat3 matrix) {
    yuv.x = yuv.x - 0.0625;
    yuv.y = yuv.y - 0.5;
    yuv.z = yuv.z - 0.5;
    return matrix * yuv;
}

vec3 adjustColor(vec3 color) {
    color += brightness;
    color = (color - 0.5) * contrast + 0.5;
    vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    color = mix(gray, color, saturation);
    color = pow(max(color, 0.0), vec3(1.0 / gamma));
    return color;
}

vec3 toneMapping(vec3 color) {
    if (!hdrEnabled) return color;
    return color / (color + vec3(1.0));
}

void main()
{
    float y = texture(textureY, TexCoord).r;
    vec2 uv = texture(textureUV, TexCoord).rg;
    
    vec3 yuv = vec3(y, uv.x, uv.y);
    vec3 rgb;
    
    if (colorSpace == 1) {
        rgb = yuv2rgb(yuv, BT601);
    } else if (colorSpace == 2) {
        rgb = yuv2rgb(yuv, BT709);
    } else if (colorSpace == 3) {
        rgb = yuv2rgb(yuv, BT2020);
    } else {
        rgb = yuv2rgb(yuv, BT709);
    }
    
    rgb = adjustColor(rgb);
    rgb = toneMapping(rgb);
    
    FragColor = vec4(clamp(rgb, 0.0, 1.0), 1.0);
}
)";

const QString VideoRenderer::s_fragmentShaderRGB = R"(
#version 330 core

in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D textureY; // RGB texture
uniform float brightness;
uniform float contrast;
uniform float saturation;
uniform float gamma;
uniform bool hdrEnabled;

vec3 adjustColor(vec3 color) {
    color += brightness;
    color = (color - 0.5) * contrast + 0.5;
    vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    color = mix(gray, color, saturation);
    color = pow(max(color, 0.0), vec3(1.0 / gamma));
    return color;
}

vec3 toneMapping(vec3 color) {
    if (!hdrEnabled) return color;
    return color / (color + vec3(1.0));
}

void main()
{
    vec3 color = texture(textureY, TexCoord).rgb;
    color = adjustColor(color);
    color = toneMapping(color);
    
    FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
)";

// Geometry data for full-screen quad
const float VideoRenderer::s_vertices[] = {
    // positions   // texCoords
    -1.0f, -1.0f, 0.0f,  0.0f, 0.0f,  // bottom left
     1.0f, -1.0f, 0.0f,  1.0f, 0.0f,  // bottom right
     1.0f,  1.0f, 0.0f,  1.0f, 1.0f,  // top right
    -1.0f,  1.0f, 0.0f,  0.0f, 1.0f   // top left
};

const unsigned int VideoRenderer::s_indices[] = {
    0, 1, 2,   // first triangle
    2, 3, 0    // second triangle
};

VideoRenderer::VideoRenderer(QWidget *parent)
    : QOpenGLWidget(parent)
    , m_shaderProgram(nullptr)
    , m_textureY(nullptr)
    , m_textureU(nullptr)
    , m_textureV(nullptr)
    , m_swsContext(nullptr)
    , m_rgbFrame(nullptr)
    , m_rgbBuffer(nullptr)
    , m_frameSize(0, 0)
    , m_aspectRatioMode(Qt::KeepAspectRatio)
    , m_rotation(0)
    , m_flipHorizontal(false)
    , m_flipVertical(false)
    , m_brightness(0.0f)
    , m_contrast(1.0f)
    , m_saturation(1.0f)
    , m_gamma(1.0f)
{
    setUpdateBehavior(QOpenGLWidget::NoPartialUpdate);
}

VideoRenderer::~VideoRenderer()
{
    makeCurrent();
    
    delete m_shaderProgram;
    delete m_textureY;
    delete m_textureU;
    delete m_textureV;
    
    if (m_swsContext) {
        sws_freeContext(m_swsContext);
    }
    
    if (m_rgbFrame) {
        av_frame_free(&m_rgbFrame);
    }
    
    if (m_rgbBuffer) {
        av_free(m_rgbBuffer);
    }
    
    doneCurrent();
}

void VideoRenderer::initializeGL()
{
    initializeOpenGLFunctions();
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glEnable(GL_TEXTURE_2D);
    
    setupShaders();
    setupGeometry();
    
    qDebug() << "VideoRenderer OpenGL initialized";
}

void VideoRenderer::setupShaders()
{
    m_shaderProgram = new QOpenGLShaderProgram(this);
    
    // 버텍스 셰이더
    const char* vertexShaderSource = R"(
        #version 330 core
        layout (location = 0) in vec3 aPos;
        layout (location = 1) in vec2 aTexCoord;
        
        out vec2 TexCoord;
        
        uniform mat4 mvpMatrix;
        
        void main()
        {
            gl_Position = mvpMatrix * vec4(aPos, 1.0);
            TexCoord = aTexCoord;
        }
    )";
    
    // 프래그먼트 셰이더 (YUV420P 지원)
    const char* fragmentShaderSource = R"(
        #version 330 core
        out vec4 FragColor;
        
        in vec2 TexCoord;
        
        uniform sampler2D textureY;
        uniform sampler2D textureU;
        uniform sampler2D textureV;
        uniform float brightness;
        uniform float contrast;
        uniform float saturation;
        uniform float gamma;
        
        void main()
        {
            float y = texture(textureY, TexCoord).r;
            float u = texture(textureU, TexCoord).r - 0.5;
            float v = texture(textureV, TexCoord).r - 0.5;
            
            // YUV to RGB conversion (BT.709)
            float r = y + 1.5748 * v;
            float g = y - 0.1873 * u - 0.4681 * v;
            float b = y + 1.8556 * u;
            
            // Color adjustments
            r = (r - 0.5) * contrast + 0.5 + brightness;
            g = (g - 0.5) * contrast + 0.5 + brightness;
            b = (b - 0.5) * contrast + 0.5 + brightness;
            
            // Saturation
            float gray = 0.299 * r + 0.587 * g + 0.114 * b;
            r = gray + saturation * (r - gray);
            g = gray + saturation * (g - gray);
            b = gray + saturation * (b - gray);
            
            // Gamma correction
            r = pow(max(r, 0.0), 1.0 / gamma);
            g = pow(max(g, 0.0), 1.0 / gamma);
            b = pow(max(b, 0.0), 1.0 / gamma);
            
            FragColor = vec4(r, g, b, 1.0);
        }
    )";
    
    if (!m_shaderProgram->addShaderFromSourceCode(QOpenGLShader::Vertex, vertexShaderSource)) {
        qWarning() << "Failed to compile vertex shader:" << m_shaderProgram->log();
        return;
    }
    
    if (!m_shaderProgram->addShaderFromSourceCode(QOpenGLShader::Fragment, fragmentShaderSource)) {
        qWarning() << "Failed to compile fragment shader:" << m_shaderProgram->log();
        return;
    }
    
    if (!m_shaderProgram->link()) {
        qWarning() << "Failed to link shader program:" << m_shaderProgram->log();
        return;
    }
    
    qDebug() << "Shaders compiled and linked successfully";
}

void VideoRenderer::setupGeometry()
{
    // 사각형 정점 데이터 (위치 + 텍스처 좌표)
    float vertices[] = {
        // 위치        // 텍스처 좌표
        -1.0f, -1.0f, 0.0f,  0.0f, 1.0f,  // 왼쪽 아래
         1.0f, -1.0f, 0.0f,  1.0f, 1.0f,  // 오른쪽 아래
         1.0f,  1.0f, 0.0f,  1.0f, 0.0f,  // 오른쪽 위
        -1.0f,  1.0f, 0.0f,  0.0f, 0.0f   // 왼쪽 위
    };
    
    unsigned int indices[] = {
        0, 1, 2,  // 첫 번째 삼각형
        2, 3, 0   // 두 번째 삼각형
    };
    
    m_vao.create();
    m_vao.bind();
    
    m_vertexBuffer.create();
    m_vertexBuffer.bind();
    m_vertexBuffer.allocate(vertices, sizeof(vertices));
    
    // 위치 속성
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    
    // 텍스처 좌표 속성
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    
    // 인덱스 버퍼
    QOpenGLBuffer indexBuffer(QOpenGLBuffer::IndexBuffer);
    indexBuffer.create();
    indexBuffer.bind();
    indexBuffer.allocate(indices, sizeof(indices));
    
    m_vao.release();
}

void VideoRenderer::paintGL()
{
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (!m_shaderProgram || !m_textureY) {
        return;
    }
    
    m_shaderProgram->bind();
    
    // 변환 행렬 설정
    QMatrix4x4 mvpMatrix = calculateTransformMatrix();
    m_shaderProgram->setUniformValue("mvpMatrix", mvpMatrix);
    
    // 색상 조정 유니폼 설정
    m_shaderProgram->setUniformValue("brightness", m_brightness);
    m_shaderProgram->setUniformValue("contrast", m_contrast);
    m_shaderProgram->setUniformValue("saturation", m_saturation);
    m_shaderProgram->setUniformValue("gamma", m_gamma);
    
    // 텍스처 바인딩
    glActiveTexture(GL_TEXTURE0);
    m_textureY->bind();
    m_shaderProgram->setUniformValue("textureY", 0);
    
    if (m_textureU) {
        glActiveTexture(GL_TEXTURE1);
        m_textureU->bind();
        m_shaderProgram->setUniformValue("textureU", 1);
    }
    
    if (m_textureV) {
        glActiveTexture(GL_TEXTURE2);
        m_textureV->bind();
        m_shaderProgram->setUniformValue("textureV", 2);
    }
    
    // 렌더링
    m_vao.bind();
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    m_vao.release();
    
    m_shaderProgram->release();
    
    emit frameRendered();
}

void VideoRenderer::resizeGL(int width, int height)
{
    glViewport(0, 0, width, height);
    calculateViewport();
}

void VideoRenderer::renderFrame(AVFrame* frame)
{
    if (!frame) return;
    
    QMutexLocker locker(&m_mutex);
    
    makeCurrent();
    updateTexture(frame);
    doneCurrent();
    
    update(); // 다음 paintGL 호출 예약
}

void VideoRenderer::updateTexture(AVFrame* frame)
{
    if (!frame || frame->width <= 0 || frame->height <= 0) return;
    
    // 프레임 크기 업데이트
    QSize newSize(frame->width, frame->height);
    if (m_frameSize != newSize) {
        m_frameSize = newSize;
        calculateViewport();
    }
    
    // 픽셀 포맷 확인
    AVPixelFormat pixFmt = static_cast<AVPixelFormat>(frame->format);
    m_pixelFormat = QString(av_get_pix_fmt_name(pixFmt));
    
    // YUV420P 형식 처리
    if (pixFmt == AV_PIX_FMT_YUV420P) {
        // Y 평면 텍스처
        if (!m_textureY) {
            m_textureY = new QOpenGLTexture(QOpenGLTexture::Target2D);
            m_textureY->setFormat(QOpenGLTexture::R8_UNorm);
            m_textureY->setMinificationFilter(QOpenGLTexture::Linear);
            m_textureY->setMagnificationFilter(QOpenGLTexture::Linear);
            m_textureY->setWrapMode(QOpenGLTexture::ClampToEdge);
        }
        
        m_textureY->setSize(frame->width, frame->height);
        m_textureY->allocateStorage();
        m_textureY->setData(QOpenGLTexture::Red, QOpenGLTexture::UInt8, frame->data[0]);
        
        // U 평면 텍스처
        if (!m_textureU) {
            m_textureU = new QOpenGLTexture(QOpenGLTexture::Target2D);
            m_textureU->setFormat(QOpenGLTexture::R8_UNorm);
            m_textureU->setMinificationFilter(QOpenGLTexture::Linear);
            m_textureU->setMagnificationFilter(QOpenGLTexture::Linear);
            m_textureU->setWrapMode(QOpenGLTexture::ClampToEdge);
        }
        
        m_textureU->setSize(frame->width / 2, frame->height / 2);
        m_textureU->allocateStorage();
        m_textureU->setData(QOpenGLTexture::Red, QOpenGLTexture::UInt8, frame->data[1]);
        
        // V 평면 텍스처
        if (!m_textureV) {
            m_textureV = new QOpenGLTexture(QOpenGLTexture::Target2D);
            m_textureV->setFormat(QOpenGLTexture::R8_UNorm);
            m_textureV->setMinificationFilter(QOpenGLTexture::Linear);
            m_textureV->setMagnificationFilter(QOpenGLTexture::Linear);
            m_textureV->setWrapMode(QOpenGLTexture::ClampToEdge);
        }
        
        m_textureV->setSize(frame->width / 2, frame->height / 2);
        m_textureV->allocateStorage();
        m_textureV->setData(QOpenGLTexture::Red, QOpenGLTexture::UInt8, frame->data[2]);
    }
    else {
        // 다른 포맷은 RGB로 변환
        convertToRGB(frame);
    }
}

void VideoRenderer::convertToRGB(AVFrame* frame)
{
    if (!frame) return;
    
    // SwsContext 초기화 (필요한 경우)
    if (!m_swsContext || 
        m_frameSize.width() != frame->width || 
        m_frameSize.height() != frame->height) {
        
        if (m_swsContext) {
            sws_freeContext(m_swsContext);
        }
        
        m_swsContext = sws_getContext(
            frame->width, frame->height, static_cast<AVPixelFormat>(frame->format),
            frame->width, frame->height, AV_PIX_FMT_RGB24,
            SWS_BILINEAR, nullptr, nullptr, nullptr
        );
        
        if (!m_swsContext) {
            emit renderingError("Failed to create SwsContext");
            return;
        }
    }
    
    // RGB 프레임 준비
    if (!m_rgbFrame) {
        m_rgbFrame = av_frame_alloc();
        if (!m_rgbFrame) {
            emit renderingError("Failed to allocate RGB frame");
            return;
        }
    }
    
    // RGB 버퍼 할당
    int bufferSize = av_image_get_buffer_size(AV_PIX_FMT_RGB24, frame->width, frame->height, 1);
    if (!m_rgbBuffer || bufferSize != av_image_get_buffer_size(AV_PIX_FMT_RGB24, m_frameSize.width(), m_frameSize.height(), 1)) {
        if (m_rgbBuffer) {
            av_free(m_rgbBuffer);
        }
        
        m_rgbBuffer = static_cast<uint8_t*>(av_malloc(bufferSize));
        if (!m_rgbBuffer) {
            emit renderingError("Failed to allocate RGB buffer");
            return;
        }
    }
    
    // RGB 프레임 설정
    av_image_fill_arrays(m_rgbFrame->data, m_rgbFrame->linesize, m_rgbBuffer, 
                        AV_PIX_FMT_RGB24, frame->width, frame->height, 1);
    
    // 변환 수행
    sws_scale(m_swsContext, frame->data, frame->linesize, 0, frame->height,
              m_rgbFrame->data, m_rgbFrame->linesize);
    
    // RGB 텍스처 업데이트
    if (!m_textureY) {
        m_textureY = new QOpenGLTexture(QOpenGLTexture::Target2D);
        m_textureY->setFormat(QOpenGLTexture::RGB8_UNorm);
        m_textureY->setMinificationFilter(QOpenGLTexture::Linear);
        m_textureY->setMagnificationFilter(QOpenGLTexture::Linear);
        m_textureY->setWrapMode(QOpenGLTexture::ClampToEdge);
    }
    
    m_textureY->setSize(frame->width, frame->height);
    m_textureY->allocateStorage();
    m_textureY->setData(QOpenGLTexture::RGB, QOpenGLTexture::UInt8, m_rgbFrame->data[0]);
}

void VideoRenderer::clearFrame()
{
    QMutexLocker locker(&m_mutex);
    
    delete m_textureY;
    delete m_textureU;
    delete m_textureV;
    
    m_textureY = nullptr;
    m_textureU = nullptr;
    m_textureV = nullptr;
    
    m_frameSize = QSize(0, 0);
    
    update();
}

void VideoRenderer::calculateViewport()
{
    if (m_frameSize.isEmpty()) {
        m_viewport = rect();
        return;
    }
    
    QSize widgetSize = size();
    QSize scaledSize = m_frameSize.scaled(widgetSize, m_aspectRatioMode);
    
    int x = (widgetSize.width() - scaledSize.width()) / 2;
    int y = (widgetSize.height() - scaledSize.height()) / 2;
    
    m_viewport = QRect(x, y, scaledSize.width(), scaledSize.height());
}

QMatrix4x4 VideoRenderer::calculateTransformMatrix()
{
    QMatrix4x4 matrix;
    
    // 회전 적용
    if (m_rotation != 0) {
        matrix.rotate(m_rotation, 0, 0, 1);
    }
    
    // 뒤집기 적용
    if (m_flipHorizontal) {
        matrix.scale(-1, 1, 1);
    }
    
    if (m_flipVertical) {
        matrix.scale(1, -1, 1);
    }
    
    return matrix;
}

// 설정 메서드들
void VideoRenderer::setAspectRatioMode(Qt::AspectRatioMode mode)
{
    if (m_aspectRatioMode != mode) {
        m_aspectRatioMode = mode;
        calculateViewport();
        update();
    }
}

void VideoRenderer::setRotation(int degrees)
{
    if (m_rotation != degrees) {
        m_rotation = degrees;
        update();
    }
}

void VideoRenderer::setFlipHorizontal(bool flip)
{
    if (m_flipHorizontal != flip) {
        m_flipHorizontal = flip;
        update();
    }
}

void VideoRenderer::setFlipVertical(bool flip)
{
    if (m_flipVertical != flip) {
        m_flipVertical = flip;
        update();
    }
}

void VideoRenderer::setBrightness(float brightness)
{
    if (m_brightness != brightness) {
        m_brightness = brightness;
        update();
    }
}

void VideoRenderer::setContrast(float contrast)
{
    if (m_contrast != contrast) {
        m_contrast = contrast;
        update();
    }
}

void VideoRenderer::setSaturation(float saturation)
{
    if (m_saturation != saturation) {
        m_saturation = saturation;
        update();
    }
}

void VideoRenderer::setGamma(float gamma)
{
    if (m_gamma != gamma) {
        m_gamma = gamma;
        update();
    }
}

// FFmpegRenderer 구현
FFmpegRenderer::FFmpegRenderer(FFmpegObject* parent)
    : m_parent(parent)
    , m_videoRenderer(nullptr)
    , m_size(1920, 1080)
{
}

FFmpegRenderer::~FFmpegRenderer()
{
    delete m_videoRenderer;
}

void FFmpegRenderer::render()
{
    // 간단한 검은 화면 렌더링
    auto* gl = QOpenGLContext::currentContext()->extraFunctions();
    gl->glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    gl->glClear(GL_COLOR_BUFFER_BIT);
}

QOpenGLFramebufferObject* FFmpegRenderer::createFramebufferObject(const QSize& size)
{
    m_size = size;
    
    QOpenGLFramebufferObjectFormat format;
    format.setSamples(4); // MSAA
    format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
    format.setTextureTarget(GL_TEXTURE_2D);
    format.setInternalTextureFormat(GL_RGBA8);
    
    return new QOpenGLFramebufferObject(size, format);
}

void FFmpegRenderer::synchronize(QQuickFramebufferObject* item)
{
    // QML 아이템과 동기화
    Q_UNUSED(item)
} 