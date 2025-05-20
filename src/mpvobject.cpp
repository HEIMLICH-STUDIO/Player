#include "mpvobject.h"
#include <stdexcept>
#include <QtQuick/QQuickWindow>
#include <QtGui/QOpenGLContext>
#include <QtOpenGL/QOpenGLFramebufferObject>
#include <QtGui/QOpenGLFunctions>
#include <QDebug>

namespace {
void on_mpv_events(void *ctx)
{
    QMetaObject::invokeMethod((MpvObject*)ctx, "handleMpvEvents", Qt::QueuedConnection);
}

void on_mpv_redraw(void *ctx)
{
    QMetaObject::invokeMethod((MpvObject*)ctx, "update", Qt::QueuedConnection);
}

static void* get_proc_address_mpv(void *ctx, const char *name)
{
    Q_UNUSED(ctx);
    QOpenGLContext *glctx = QOpenGLContext::currentContext();
    if (!glctx) return nullptr;
    return reinterpret_cast<void*>(glctx->getProcAddress(QByteArray(name)));
}
}

class MpvRenderer : public QQuickFramebufferObject::Renderer
{
    MpvObject *obj;

public:
    MpvRenderer(MpvObject *new_obj) : obj(new_obj) {}
    ~MpvRenderer() {}

    QOpenGLFramebufferObject * createFramebufferObject(const QSize &size)
    {
        // Initialize mpv_render_context when the first frame is rendered
        if (!obj->mpv_context)
        {
            qDebug() << "Creating MPV render context with size:" << size;
            
            // GL 함수 획득 함수 설정
            mpv_opengl_init_params gl_init_params{get_proc_address_mpv, nullptr};
            
            // Windows에서 더 안정적인 렌더링 파라미터
            mpv_render_param params[]{
                {MPV_RENDER_PARAM_API_TYPE, const_cast<char*>(MPV_RENDER_API_TYPE_OPENGL)},
                {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
                {MPV_RENDER_PARAM_INVALID, nullptr}
            };

            int err = mpv_render_context_create(&obj->mpv_context, obj->mpv, params);
            if (err < 0) {
                qCritical() << "Failed to initialize mpv GL context, error code:" << err;
                return nullptr;
            }
            
            qDebug() << "MPV render context created successfully";
            mpv_render_context_set_update_callback(obj->mpv_context, on_mpv_redraw, obj);
        }
        
        // 기본 프레임버퍼 객체 생성 (4바이트 RGBA 텍스처 형식으로 설정)
        QOpenGLFramebufferObjectFormat format;
        format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        
        QOpenGLFramebufferObject* fbo = new QOpenGLFramebufferObject(size, format);
        qDebug() << "Created FBO with handle:" << fbo->handle() << "size:" << size;
        return fbo;
    }

    void render()
    {
        if (!obj->mpv_context) {
            qWarning() << "Render called but no MPV context available";
            return;
        }

        QOpenGLFramebufferObject *fbo = framebufferObject();
        if (!fbo) {
            qWarning() << "No framebuffer object available for rendering";
            return;
        }
        
        // MPV 렌더링 시작
        fbo->bind();

        // FBO 정보 설정
        mpv_opengl_fbo mpfbo{
            static_cast<int>(fbo->handle()), 
            fbo->width(), 
            fbo->height(), 
            0  // 내부 포맷
        };
        
        // 추가 렌더링 파라미터 설정
        int flip_y = 0;  // OpenGL 좌표계에서는 필요 없음
        
        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_OPENGL_FBO, &mpfbo},
            {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
            {MPV_RENDER_PARAM_INVALID, nullptr}
        };
        
        // 실제 MPV 렌더링 수행
        mpv_render_context_render(obj->mpv_context, params);
        
        // FBO 바인딩 해제
        fbo->release();
    }

    void swap() 
    {
        // No-op - QQuickFramebufferObject handles the swap
    }

    // 비디오 해상도 변경 핸들러
    void onVideoResize() 
    {
        if (!obj->mpv_context)
            return;
            
        invalidateFramebufferObject();
    }
    
    // 비디오 재생 상태 변경 핸들러
    void onVideoPlaybackActive(bool active) 
    {
        if (active) {
            update();
        }
    }
};

MpvObject::MpvObject(QQuickItem * parent)
    : QQuickFramebufferObject(parent), mpv(nullptr), mpv_context(nullptr)
{
    qDebug() << "MpvObject constructor starting...";
    mpv = mpv_create();
    if (!mpv) {
        qCritical() << "Failed to create MPV context";
        throw std::runtime_error("Could not create mpv context");
    }

    // 기본 MPV 옵션 설정
    mpv_set_option_string(mpv, "vo", "libmpv");
    
    // 하드웨어 가속 설정
    mpv_set_option_string(mpv, "hwdec", "auto");
    
    // GPU 설정
    mpv_set_option_string(mpv, "gpu-api", "auto");
    
    // 소프트웨어 렌더링 허용 (필요시)
    mpv_set_option_string(mpv, "gpu-sw", "yes");
    
    // 기본 비디오 회전 설정 (180도 회전 수정)
    // mpv_set_option_string(mpv, "video-rotate", "180");
    
    // 로그 레벨 설정
    mpv_set_option_string(mpv, "msg-level", "all=v");
    
    // 프로퍼티 감시 설정
    mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(mpv, 0, "duration", MPV_FORMAT_DOUBLE);
    mpv_observe_property(mpv, 0, "media-title", MPV_FORMAT_STRING);
    mpv_observe_property(mpv, 0, "filename", MPV_FORMAT_STRING);
    mpv_observe_property(mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_observe_property(mpv, 0, "mute", MPV_FORMAT_FLAG);
    
    // 이벤트 콜백 설정
    mpv_set_wakeup_callback(mpv, on_mpv_events, this);
    
    if (mpv_initialize(mpv) < 0) {
        qCritical() << "Failed to initialize MPV";
        throw std::runtime_error("Could not initialize mpv context");
    }
    
    qDebug() << "MpvObject constructor completed successfully";
    
    setMirrorVertically(true);
}

MpvObject::~MpvObject()
{
    if (mpv_context)
    {
        mpv_render_context_free(mpv_context);
    }
    if (mpv)
    {
        mpv_terminate_destroy(mpv);
    }
}

QQuickFramebufferObject::Renderer *MpvObject::createRenderer() const
{
    window()->setPersistentSceneGraph(true);
    return new MpvRenderer(const_cast<MpvObject*>(this));
}

void MpvObject::handleMpvEvents()
{
    while (mpv)
    {
        mpv_event *event = mpv_wait_event(mpv, 0);
        if (event->event_id == MPV_EVENT_NONE)
            break;
            
        switch (event->event_id)
        {
        case MPV_EVENT_PROPERTY_CHANGE:
        {
            mpv_event_property *prop = (mpv_event_property *)event->data;
            
            if (strcmp(prop->name, "pause") == 0 && prop->format == MPV_FORMAT_FLAG) {
                int value = *(int *)prop->data;
                bool paused = value != 0;
                m_pause = paused;
                emit pauseChanged(paused);
                emit playingChanged(!paused);
            }
            else if (strcmp(prop->name, "time-pos") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                double pos = *(double *)prop->data;
                m_position = pos;
                emit positionChanged(pos);
            }
            else if (strcmp(prop->name, "duration") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                double duration = *(double *)prop->data;
                m_duration = duration;
                emit durationChanged(duration);
            }
            else if (strcmp(prop->name, "media-title") == 0 && prop->format == MPV_FORMAT_STRING) {
                char *title = *(char **)prop->data;
                m_mediaTitle = QString::fromUtf8(title);
                emit mediaTitleChanged(m_mediaTitle);
            }
            else if (strcmp(prop->name, "filename") == 0 && prop->format == MPV_FORMAT_STRING) {
                char *filename = *(char **)prop->data;
                m_filename = QString::fromUtf8(filename);
                emit filenameChanged(m_filename);
            }
            else if (strcmp(prop->name, "volume") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                double vol = *(double *)prop->data;
                m_volume = vol;
                emit volumeChanged(vol);
            }
            else if (strcmp(prop->name, "mute") == 0 && prop->format == MPV_FORMAT_FLAG) {
                int value = *(int *)prop->data;
                bool muted = value != 0;
                m_muted = muted;
                emit mutedChanged(muted);
            }
            break;
        }
        case MPV_EVENT_VIDEO_RECONFIG:
            emit videoReconfig();
            break;
        default:
            break;
        }
    }
}

void MpvObject::command(const QVariant& params)
{
    if (params.canConvert<QVariantList>()) {
        QVariantList args = params.toList();
        int num = args.size();
        QVector<QByteArray> byteArrays;
        QVector<const char*> command;
        
        if (num > 0) {
            byteArrays.reserve(num);
            command.reserve(num + 1);
            
            for (int i = 0; i < num; i++) {
                byteArrays.append(args[i].toString().toUtf8());
                command.append(byteArrays.last().constData());
            }
            command.append(nullptr);
            
            mpv_command(mpv, command.data());
        }
    }
}

void MpvObject::setProperty(const QString& name, const QVariant& value)
{
    if (value.type() == QVariant::Bool) {
        int flag = value.toBool() ? 1 : 0;
        mpv_set_property(mpv, name.toUtf8().constData(), MPV_FORMAT_FLAG, &flag);
    } 
    else if (value.type() == QVariant::Double) {
        double val = value.toDouble();
        mpv_set_property(mpv, name.toUtf8().constData(), MPV_FORMAT_DOUBLE, &val);
    } 
    else if (value.type() == QVariant::String) {
        QByteArray bytes = value.toString().toUtf8();
        mpv_set_property_string(mpv, name.toUtf8().constData(), bytes.constData());
    }
}

QVariant MpvObject::getProperty(const QString& name)
{
    mpv_format format;
    void* value = nullptr;
    
    if (name == "pause") {
        format = MPV_FORMAT_FLAG;
        int val;
        value = &val;
    } 
    else if (name == "time-pos" || name == "duration") {
        format = MPV_FORMAT_DOUBLE;
        double val;
        value = &val;
    } 
    else {
        format = MPV_FORMAT_STRING;
        char* val;
        value = &val;
    }
    
    int result = mpv_get_property(mpv, name.toUtf8().constData(), format, value);
    
    if (result < 0) {
        return QVariant();
    }
    
    switch (format) {
        case MPV_FORMAT_FLAG:
            return QVariant(*reinterpret_cast<int*>(value) != 0);
        case MPV_FORMAT_DOUBLE:
            return QVariant(*reinterpret_cast<double*>(value));
        case MPV_FORMAT_STRING: {
            QVariant ret = QVariant(QString::fromUtf8(*reinterpret_cast<char**>(value)));
            mpv_free(*reinterpret_cast<char**>(value));
            return ret;
        }
        default:
            return QVariant();
    }
}

void MpvObject::play()
{
    setProperty("pause", false);
}

void MpvObject::pause()
{
    setProperty("pause", true);
}

void MpvObject::playPause()
{
    bool paused = getProperty("pause").toBool();
    setProperty("pause", !paused);
}

void MpvObject::setVolume(double volume)
{
    m_volume = volume;
    mpv_set_property(mpv, "volume", MPV_FORMAT_DOUBLE, &volume);
    emit volumeChanged(volume);
}

void MpvObject::setMuted(bool muted)
{
    int flag = muted ? 1 : 0;
    m_muted = muted;
    mpv_set_property(mpv, "mute", MPV_FORMAT_FLAG, &flag);
    emit mutedChanged(muted);
}
