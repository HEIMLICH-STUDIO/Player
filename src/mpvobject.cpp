#include "mpvobject.h"
#include <stdexcept>
#include <QtQuick/QQuickWindow>
#include <QtGui/QOpenGLContext>
#include <QtOpenGL/QOpenGLFramebufferObject>
#include <QtGui/QOpenGLFunctions>
#include <QDebug>
#include <QDateTime>

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
            
            // 고성능 렌더링 파라미터 설정
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
        
        // 고성능 프레임버퍼 객체 생성 설정
        QOpenGLFramebufferObjectFormat format;
        format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        
        // 멀티샘플링 활성화 (부드러운 렌더링)
        format.setSamples(4);
        
        QOpenGLFramebufferObject* fbo = new QOpenGLFramebufferObject(size, format);
                                                    // qDebug() << "Created FBO with handle:" << fbo->handle() << "size:" << size;
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
        
        // 고성능 렌더링 파라미터 설정
        int flip_y = 0;  // OpenGL 좌표계에서는 필요 없음
        int skip_rendering = 0;  // 항상 렌더링 수행
        int block_for_target = 0;  // 비동기 렌더링
        
        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_OPENGL_FBO, &mpfbo},
            {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
            {MPV_RENDER_PARAM_SKIP_RENDERING, &skip_rendering},
            {MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME, &block_for_target},
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
    // qDebug() << "MpvObject constructor starting...";
    mpv = mpv_create();
    if (!mpv) {
        qCritical() << "Failed to create MPV context";
        throw std::runtime_error("Could not create mpv context");
    }

    // 기본 MPV 옵션 설정 - 성능 및 안정성 개선
    mpv_set_option_string(mpv, "vo", "libmpv");
    
    // 하드웨어 가속 설정 - 더 안정적인 옵션
    mpv_set_option_string(mpv, "hwdec", "auto-copy");
    
    // 안정적인 GPU 설정
    mpv_set_option_string(mpv, "gpu-api", "auto");
    
    // 시크 관련 설정 최적화
    mpv_set_option_string(mpv, "hr-seek", "yes");
    mpv_set_option_string(mpv, "hr-seek-framedrop", "yes");
    
    // 프레임 드랍 제한 - 최소화
    mpv_set_option_string(mpv, "framedrop", "no");
    
    // 성능 최적화 - 버퍼링 설정
    mpv_set_option_string(mpv, "cache", "yes");
    mpv_set_option_string(mpv, "cache-secs", "10");
    mpv_set_option_string(mpv, "demuxer-max-bytes", "100M");
    mpv_set_option_string(mpv, "demuxer-max-back-bytes", "100M");
    
    // 렌더링 성능 최적화
    mpv_set_option_string(mpv, "gpu-dumb-mode", "no");
    mpv_set_option_string(mpv, "vd-lavc-threads", "4");
    
    // 동기화 설정 조정
    mpv_set_option_string(mpv, "video-sync", "display-resample");
    mpv_set_option_string(mpv, "video-timing-offset", "0");
    
    // 초기 속도 설정
    mpv_set_option_string(mpv, "speed", "1.0");
    
    // 로그 레벨 설정 - 에러와 경고만 표시
    mpv_set_option_string(mpv, "msg-level", "all=error");
    
    // 기본적으로 반복 재생 비활성화
    mpv_set_option_string(mpv, "loop", "no");
    
    // 프로퍼티 감시 설정
    mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(mpv, 0, "duration", MPV_FORMAT_DOUBLE);
    mpv_observe_property(mpv, 0, "media-title", MPV_FORMAT_STRING);
    mpv_observe_property(mpv, 0, "filename", MPV_FORMAT_STRING);
    mpv_observe_property(mpv, 0, "estimated-vf-fps", MPV_FORMAT_DOUBLE);
    mpv_observe_property(mpv, 0, "eof-reached", MPV_FORMAT_FLAG);
    
    // 이벤트 콜백 설정
    mpv_set_wakeup_callback(mpv, on_mpv_events, this);
    
    if (mpv_initialize(mpv) < 0) {
        qCritical() << "Failed to initialize MPV";
        throw std::runtime_error("Could not initialize mpv context");
    }
    
    // qDebug() << "MpvObject constructor completed successfully";
    
    setMirrorVertically(true);
    
    // 상태 변경 타이머
    m_stateChangeTimer = new QTimer(this);
    m_stateChangeTimer->setSingleShot(true);
    m_stateChangeTimer->setInterval(50); // 적절한 지연
    connect(m_stateChangeTimer, &QTimer::timeout, this, &MpvObject::processStateChange);
    
    // 성능 모니터링 설정
    m_performanceTimer = new QTimer(this);
    m_performanceTimer->setInterval(1000); // 1초마다 체크
    m_performanceTimer->setSingleShot(false);
    connect(m_performanceTimer, &QTimer::timeout, this, &MpvObject::checkPerformance);
    m_performanceTimer->start();
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
    // 예외로부터 보호하기 위해 try-catch 추가
    try {
        while (mpv) {
        mpv_event *event = mpv_wait_event(mpv, 0);
        if (event->event_id == MPV_EVENT_NONE)
            break;
            
            switch (event->event_id) {
        case MPV_EVENT_PROPERTY_CHANGE:
        {
            mpv_event_property *prop = (mpv_event_property *)event->data;
            
            if (strcmp(prop->name, "pause") == 0 && prop->format == MPV_FORMAT_FLAG) {
                    if (!prop->data) {
                        qWarning() << "Invalid pause property data";
                        continue;
                    }
                int value = *(int *)prop->data;
                bool paused = value != 0;
                
                    // 일시 정지 상태 즉시 처리
                    if (m_pause != paused) {
                        m_pause = paused;
                        emit pauseChanged(m_pause);
                        emit playingChanged(!m_pause);
                        update();
                }
            }
            else if (strcmp(prop->name, "time-pos") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                    if (!prop->data) {
                        qWarning() << "Invalid time-pos property data";
                        continue;
                    }
                double pos = *(double *)prop->data;
                    
                    // 시크 후에도 정확한 포지션 유지를 위해 최소 변화량 체크 완화
                    if (std::abs(pos - m_position) > 0.001) {
                        // 이전 위치 기록
                        double prevPos = m_position;
                        m_position = pos;
                        m_lastPosition = pos; // 일관성 유지
                        
                        // 현재 재생 방향 감지 (재생 중일 때 활용)
                        bool isMovingForward = (pos > prevPos);
                        
                        // 영상 끝에 도달했는지 확인 - 더 정밀하게 판단
                        if (m_duration > 0) {
                            // 1. 일반 판단: 끝에 가까워짐
                            bool nearEnd = (pos >= m_duration - 0.5);
                            
                            // 2. 정밀 판단: 재생 방향과 위치 변화량 고려
                            bool preciseFinalFrame = false;
                            if (!m_pause && isMovingForward) {
                                // 재생 중이고 앞으로 이동 중일 때
                                // 마지막 위치가 이전 위치와 거의 같으면 (멈춤 감지)
                                preciseFinalFrame = (nearEnd && std::abs(pos - prevPos) < 0.01);
                            }
                            
                            // 끝 도달 조건: 명확한 끝 도달 OR 정밀한 끝 프레임 감지
                            bool reachedEnd = (pos > m_duration - 0.01) || preciseFinalFrame;
                            
                            if (reachedEnd) {
                                if (!m_endReached) {
                                    qDebug() << "Video end detected at position:" << pos 
                                             << "(Duration:" << m_duration 
                                             << ", Gap:" << (m_duration - pos) << ")";
                                    handleEndOfVideo();
                                }
                            } else if (pos < m_duration - 1.0) {
                                // 끝에서 충분히 벗어났을 때만 endReached 상태 초기화
                                if (m_endReached) {
                                    resetEndReached();
                                }
                            }
                        }
                        
                        emit positionChanged(m_position);
                            update();
                        }
                }
                else if (strcmp(prop->name, "duration") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                    if (!prop->data) {
                        qWarning() << "Invalid duration property data";
                        continue;
            }
                double duration = *(double *)prop->data;
                m_duration = duration;
                    
                    // 총 프레임 수 업데이트 
                    updateFrameCount();
                    
                emit durationChanged(duration);
            }
            else if (strcmp(prop->name, "media-title") == 0 && prop->format == MPV_FORMAT_STRING) {
                    if (!prop->data) {
                        qWarning() << "Invalid media-title property data";
                        continue;
                    }
                char *title = *(char **)prop->data;
                m_mediaTitle = QString::fromUtf8(title);
                emit mediaTitleChanged(m_mediaTitle);
            }
            else if (strcmp(prop->name, "filename") == 0 && prop->format == MPV_FORMAT_STRING) {
                    if (!prop->data) {
                        qWarning() << "Invalid filename property data";
                        continue;
                    }
                char *filename = *(char **)prop->data;
                m_filename = QString::fromUtf8(filename);
                    
                    // 새 파일 로드 시 상태 초기화
                    m_endReached = false;
                    m_position = 0;
                    m_lastPosition = 0;
                    
                emit filenameChanged(m_filename);
                    emit endReachedChanged(false);
                    
                    // 무조건 일시정지 상태로 시작
                    if (!m_pause) {
                        command(QVariantList() << "set_property" << "pause" << true);
                    }
                    
                    // 파일 로드 후 0.5초 뒤 프레임 개수를 확인하는 타이머
                    QTimer::singleShot(500, this, &MpvObject::updateFrameCount);
                }
                else if (strcmp(prop->name, "estimated-vf-fps") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                    if (!prop->data) {
                        qWarning() << "Invalid fps property data";
                        continue;
                    }
                    double fps = *(double *)prop->data;
                    if (fps > 0) {
                        // FPS 값을 소수점 3자리로 고정
                        m_fps = std::round(fps * 1000.0) / 1000.0;
                        
                        // FPS 변경 시 총 프레임 수도 업데이트
                        updateFrameCount();
                        
                        emit fpsChanged(m_fps);
                    }
                }
                else if (strcmp(prop->name, "eof-reached") == 0 && prop->format == MPV_FORMAT_FLAG) {
                    if (!prop->data) {
                        qWarning() << "Invalid eof-reached property data";
                        continue;
                    }
                    
                    int value = *(int *)prop->data;
                    bool eofReached = value != 0;
                    
                    if (eofReached) {
                        qDebug() << "EOF signal detected from MPV";
                        handleEndOfVideo();
                    }
            }
            break;
        }
        case MPV_EVENT_VIDEO_RECONFIG:
            emit videoReconfig();
                // 비디오 설정이 변경되면 총 프레임 수도 다시 계산
                QTimer::singleShot(300, this, &MpvObject::updateFrameCount);
                break;
            case MPV_EVENT_END_FILE:
            {
                mpv_event_end_file *endFile = (mpv_event_end_file *)event->data;
                if (endFile && endFile->reason == MPV_END_FILE_REASON_EOF) {
                    qDebug() << "END_FILE event received with EOF reason";
                    handleEndOfVideo();
                } else {
                    qDebug() << "END_FILE event received with reason:" 
                             << (endFile ? endFile->reason : -1);
                }
                break;
            }
            case MPV_EVENT_FILE_LOADED:
                // 파일 로드 완료 후 프레임 수 업데이트
                QTimer::singleShot(200, this, &MpvObject::updateFrameCount);
            break;
        default:
            break;
        }
        }
    } catch (const std::exception& e) {
        qCritical() << "Exception in handleMpvEvents:" << e.what();
    } catch (...) {
        qCritical() << "Unknown exception in handleMpvEvents";
    }
}

// MPV 명령 실행 함수 - 안정성 강화
void MpvObject::command(const QVariant& params)
{
    try {
        if (!mpv) {
            qWarning() << "No MPV instance available for command";
            return;
        }
        
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
            
                // 명령 로깅 (디버깅용)
                if (num > 0 && byteArrays[0] != "get_property") {
                    QString cmdStr = byteArrays[0];
                    if (cmdStr == "seek" && num > 1) {
                        qDebug() << "MPV seek to:" << byteArrays[1];
                    } else if (num > 1) {
                        qDebug() << "MPV command:" << cmdStr << byteArrays[1];
                    }
                }
                
                // 명령 안전하게 실행
                int result = mpv_command(mpv, command.data());
                if (result < 0) {
                    QString error = QString("MPV command failed: %1 (code %2)").arg(mpv_error_string(result)).arg(result);
                    qWarning() << error;
        }
    }
}
    } catch (const std::exception& e) {
        qCritical() << "Exception in command:" << e.what();
    } catch (...) {
        qCritical() << "Unknown exception in command";
    }
}

// MPV 속성 설정 함수 - 안정성 강화
void MpvObject::setProperty(const QString& name, const QVariant& value)
{
    try {
        if (!mpv) {
            qWarning() << "No MPV instance available for setProperty";
            return;
        }
        
        QByteArray nameBytes = name.toUtf8();
        const char* nameStr = nameBytes.constData();
        
        // 더 안정적인 속성 설정
        if (value.canConvert<bool>()) {
        int flag = value.toBool() ? 1 : 0;
            // 재생/일시 정지는 강제 실행
            if (name == "pause") {
                mpv_command_string(mpv, QString("set pause %1").arg(flag).toUtf8().constData());
                
                // 직접 내부 상태 업데이트
                m_pause = value.toBool();
                emit pauseChanged(m_pause);
                emit playingChanged(!m_pause);
            } else {
                mpv_set_property(mpv, nameStr, MPV_FORMAT_FLAG, &flag);
            }
    } 
        else if (value.canConvert<double>()) {
        double val = value.toDouble();
            // 중요 속성은 명령으로 처리
            if (name == "time-pos") {
                // 시크 함수 호출
                seekToPosition(val);
            } else if (name == "speed") {
                // 속도는 명령으로 설정 (더 안정적)
                mpv_command_string(mpv, QString("set speed %1").arg(val).toUtf8().constData());
            } else {
                mpv_set_property(mpv, nameStr, MPV_FORMAT_DOUBLE, &val);
            }
    } 
        else if (value.canConvert<QString>()) {
        QByteArray bytes = value.toString().toUtf8();
            mpv_set_property_string(mpv, nameStr, bytes.constData());
        }
    } catch (const std::exception& e) {
        qCritical() << "Exception in setProperty:" << e.what();
    } catch (...) {
        qCritical() << "Unknown exception in setProperty";
    }
}

// 새로운 함수: 안전하고 정확한 시크 처리
void MpvObject::seekToPosition(double pos)
{
    try {
        if (!mpv || m_duration <= 0) {
            return;
        }
        
        // 시크 전에 지연 중인 타이머 취소
        m_lastSeekTime = QDateTime::currentMSecsSinceEpoch();
        
        // 시크하면 endReached 상태 초기화
        resetEndReached();
        
        // 안전한 시크 범위 계산
        double safePosition = qBound(0.0, pos, m_duration - 0.5);
        
        // 영상 끝 부분에 대한 안전 체크
        bool isTooCloseToEnd = (m_duration - safePosition) < 0.5;
        double finalSeekPos = safePosition;
        
        // 너무 끝에 가까우면 더 안전한 위치로 조정
        if (isTooCloseToEnd) {
            finalSeekPos = m_duration - 0.75; // 끝에서 약간 더 떨어진 위치
        }
        
        qDebug() << "Seeking to:" << finalSeekPos << "(requested:" << pos << ")";
        
        // 1. 먼저 일시정지 설정
        mpv_command_string(mpv, "set pause yes");
        if (!m_pause) {
            m_pause = true;
            emit pauseChanged(true);
            emit playingChanged(false);
        }
        
        // 2. 정확한 시크 수행
        mpv_command_string(mpv, QString("seek %1 absolute exact").arg(finalSeekPos).toUtf8().constData());
        
        // 3. 위치 정보 업데이트
        m_position = finalSeekPos;
        m_lastPosition = finalSeekPos;
        emit positionChanged(finalSeekPos);
        
        // 4. UI 강제 갱신
        update();
        
        // 5. 시크 후 정확한 위치 확인을 위한 타이머
        QTimer::singleShot(50, this, [this, finalSeekPos]() {
            try {
                // 시크된 위치 확인
                QVariant posVal = getProperty("time-pos");
                if (posVal.isValid()) {
                    double actualPos = posVal.toDouble();
                    if (std::abs(actualPos - finalSeekPos) > 0.1) {
                        // 실제 위치가 요청한 위치와 많이 다르면 다시 시크
                        qDebug() << "Seek verification: target=" << finalSeekPos 
                                 << "actual=" << actualPos << "retrying...";
                        mpv_command_string(mpv, QString("seek %1 absolute exact")
                                           .arg(finalSeekPos).toUtf8().constData());
    }
}
            } catch (...) {
                qWarning() << "Error in seek verification";
            }
        });
    } catch (const std::exception& e) {
        qCritical() << "Exception in seekToPosition:" << e.what();
    } catch (...) {
        qCritical() << "Unknown exception in seekToPosition";
    }
}

// MPV 속성 읽기 함수 - 안전성 강화
QVariant MpvObject::getProperty(const QString& name)
{
    try {
        if (!mpv) {
            return QVariant();
        }
        
        // 이미 알고 있는 값이면 직접 반환 (속도 개선)
        if (name == "pause") {
            return QVariant(m_pause);
        } else if (name == "time-pos") {
            return QVariant(m_position);
        } else if (name == "duration") {
            return QVariant(m_duration);
        } else if (name == "media-title") {
            return QVariant(m_mediaTitle);
        } else if (name == "estimated-vf-fps") {
            return QVariant(m_fps);
        } else if (name == "estimated-frame-count") {
            return QVariant(m_frameCount);
        }
        
    mpv_format format;
    void* value = nullptr;
    
    if (name == "pause") {
        format = MPV_FORMAT_FLAG;
        int val;
        value = &val;
    } 
        else if (name == "time-pos" || name == "duration" || name == "speed" || 
                name == "estimated-vf-fps" || name == "estimated-frame-number" || 
                name == "frame-count") {
        format = MPV_FORMAT_DOUBLE;
        double val;
        value = &val;
    } 
    else {
        format = MPV_FORMAT_STRING;
        char* val;
        value = &val;
    }
    
        QByteArray nameBytes = name.toUtf8();
        int result = mpv_get_property(mpv, nameBytes.constData(), format, value);
    
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
    } catch (...) {
            return QVariant();
    }
}

// 재생 함수 - 간소화
void MpvObject::play()
{
    try {
    setProperty("pause", false);
    } catch (const std::exception& e) {
        qCritical() << "Exception in play:" << e.what();
    }
}

// 일시 정지 함수 - 간소화
void MpvObject::pause()
{
    try {
    setProperty("pause", true);
    } catch (const std::exception& e) {
        qCritical() << "Exception in pause:" << e.what();
    }
}

// 재생/일시정지 토글 함수 - 간소화
void MpvObject::playPause()
{
    try {
        bool paused = isPaused();
    setProperty("pause", !paused);
    } catch (const std::exception& e) {
        qCritical() << "Exception in playPause:" << e.what();
    }
}

// 포지션 업데이트 함수 - 제거 (불필요한 중복 호출 방지)
void MpvObject::updatePositionProperty()
{
    // 이 함수는 더 이상 사용되지 않음 (타이머 중복 제거)
}

// 지연된 상태 변경 처리 함수 - 간소화
void MpvObject::processStateChange()
{
    try {
    if (m_pause != m_pendingPauseState) {
        m_pause = m_pendingPauseState;
        emit pauseChanged(m_pause);
        emit playingChanged(!m_pause);
            update();
        }
    } catch (const std::exception& e) {
        qCritical() << "Exception in processStateChange:" << e.what();
    }
}

// 새로운 메서드: FPS 값 얻기
double MpvObject::fps() const
{
    return m_fps;
}

// 새로운 메서드: 성능 모니터링
void MpvObject::checkPerformance()
{
    if (!mpv || m_filename.isEmpty()) return;
    
    try {
        // 현재 시간과 마지막 체크 시간 간의 차이 계산
        QDateTime now = QDateTime::currentDateTime();
        
        if (!m_lastPerformanceCheck.isValid()) {
            m_lastPerformanceCheck = now;
            return;
        }
        
        qint64 elapsed = m_lastPerformanceCheck.msecsTo(now);
        m_lastPerformanceCheck = now;
        
        if (elapsed <= 0) return;
        
        // 재생 중일 때만 체크
        if (!m_pause && m_duration > 0) {
            // FPS 체크
            QVariant fps = getProperty("estimated-vf-fps");
            if (fps.isValid() && fps.toDouble() > 0) {
                double fpsValue = fps.toDouble();
                // 필요한 경우 성능 최적화 적용
                if (fpsValue < m_fps * 0.8) { // FPS가 20% 이상 떨어졌다면
                    qDebug() << "Performance warning: FPS dropped to" << fpsValue << "(expected" << m_fps << ")";
                    
                    // 성능 최적화 단계 적용
                    if (!m_performanceOptimizationApplied) {
                        qDebug() << "Applying performance optimizations";
                        command(QVariantList() << "set_property" << "scale" << "bilinear");
                        command(QVariantList() << "set_property" << "hwdec" << "auto-copy");
                        m_performanceOptimizationApplied = true;
                    }
                }
            }
        }
    } catch (const std::exception& e) {
        qWarning() << "Performance check error:" << e.what();
    } catch (...) {
        qWarning() << "Unknown error in performance check";
    }
}

// 비디오 종료 처리를 일관되게 관리하는 함수
void MpvObject::handleEndOfVideo()
{
    try {
        // 이미 처리했다면 중복 처리 방지
        if (m_endReached) {
            return;
        }
        
        qDebug() << "Handling end of video at position:" << m_position;
        m_endReached = true;
        emit endReachedChanged(true);
        
        // 항상 일시 정지 먼저 설정
        if (!m_pause) {
            command(QVariantList() << "set_property" << "pause" << true);
            m_pause = true;
            emit pauseChanged(m_pause);
            emit playingChanged(false);
        }
        
        // 안전한 위치로 이동 (마지막 프레임에서 약간 앞으로)
        if (m_duration > 0) {
            // 1. 먼저 정확한 현재 위치 확인
            double exactPos = m_position;
            try {
                double checkPos = getProperty("time-pos").toDouble();
                if (checkPos > 0) {
                    exactPos = checkPos;
                }
            } catch (...) {}
            
            // 2. 안전한 위치 계산
            double endThreshold = 0.1; // 끝에서 최소 0.1초 전
            double targetPos = 0;
            
            // 실제 마지막 프레임 위치 계산 (1/fps 만큼 앞으로) - 프레임 오프셋 고려
            double lastFramePos = m_duration - (1.0 / m_fps);
            
            if (exactPos > m_duration - endThreshold) {
                // 이미 끝에 매우 가까우면 마지막 프레임 정확한 위치로 이동
                targetPos = std::max(0.0, lastFramePos);
            } else {
                // 현재 위치가 괜찮으면 그대로 유지
                targetPos = exactPos;
            }
            
            // 현재 위치 업데이트
            m_position = targetPos;
            m_lastPosition = targetPos;
            
            // 일시정지 상태에서 안전한 위치로 시크
            command(QVariantList() << "seek" << targetPos << "absolute" << "exact");
            emit positionChanged(targetPos);
            
            // 루프 모드가 활성화된 경우 처리
            if (m_loopEnabled) {
                // 루프 시작 처리 타이머로 지연 (MPV가 완전히 시크를 끝내도록)
                QTimer::singleShot(150, this, [this]() {
                    try {
                        qDebug() << "Loop activated, going back to start";
                        
                        // 영상의 시작으로 돌아가기 (0초)
                        command(QVariantList() << "seek" << 0 << "absolute" << "exact");
                        
                        // 상태 업데이트
                        m_position = 0;
                        m_lastPosition = 0;
                        emit positionChanged(0);
                        
                        // 다시 재생 시작 (0.2초 지연 - 첫 프레임이 정확히 표시되도록)
                        QTimer::singleShot(200, this, [this]() {
                            command(QVariantList() << "set_property" << "pause" << false);
                            m_pause = false;
                            emit pauseChanged(false);
                            emit playingChanged(true);
                            
                            // endReached 상태 리셋
                            m_endReached = false;
                            emit endReachedChanged(false);
                            
                            // 화면 갱신
                update();
            });
                    } catch (const std::exception& e) {
                        qCritical() << "Exception in loop handling:" << e.what();
                    } catch (...) {
                        qCritical() << "Unknown exception in loop handling";
                    }
                });
            }
        }
        
        // 화면 강제 갱신
        update();
    }
    catch (const std::exception& e) {
        qCritical() << "Exception in handleEndOfVideo:" << e.what();
    }
    catch (...) {
        qCritical() << "Unknown exception in handleEndOfVideo";
    }
}

// 비디오 종료 상태 초기화
void MpvObject::resetEndReached()
{
    if (m_endReached) {
        m_endReached = false;
        emit endReachedChanged(false);
    }
}

// endReached 읽기 함수
bool MpvObject::isEndReached() const
{
    return m_endReached;
}

// 반복 모드 확인 함수
bool MpvObject::isLoopEnabled() const
{
    return m_loopEnabled;
}

// 반복 모드 설정 함수
void MpvObject::setLoopEnabled(bool enabled)
{
    if (m_loopEnabled != enabled) {
        m_loopEnabled = enabled;
        
        // MPV 속성 설정
        command(QVariantList() << "set_property" << "loop" << (enabled ? "inf" : "no"));
        
        emit loopChanged(enabled);
    }
}

// 접근자 메서드 구현
QString MpvObject::filename() const
{
    return m_filename;
}

bool MpvObject::isPaused() const
{
    return m_pause;
}

double MpvObject::position() const
{
    return m_position;
}

double MpvObject::duration() const
{
    return m_duration;
}

QString MpvObject::mediaTitle() const
{
    return m_mediaTitle;
}

// 총 프레임 수 계산 메서드 추가
void MpvObject::updateFrameCount()
{
    if (!mpv || m_filename.isEmpty() || m_duration <= 0 || m_fps <= 0) {
        return;
    }
    
    try {
        qDebug() << "Updating frame count...";
        
        // MPV에서 직접 프레임 수 가져오기 시도
        QVariant frameCountVar = getProperty("estimated-frame-count");
        QVariant exactFramesVar = getProperty("frame-count");
        
        // 프레임 수 계산 방식 1: MPV 내장 프레임 수
        if (exactFramesVar.isValid() && exactFramesVar.toInt() > 0) {
            m_frameCount = exactFramesVar.toInt();
            qDebug() << "Exact frame count from MPV:" << m_frameCount;
        }
        // 프레임 수 계산 방식 2: 추정 프레임 수
        else if (frameCountVar.isValid() && frameCountVar.toInt() > 0) {
            m_frameCount = frameCountVar.toInt();
            qDebug() << "Estimated frame count from MPV:" << m_frameCount;
        } 
        // 프레임 수 계산 방식 3: 지속 시간 * FPS (가장 기본적인 계산법)
        else {
            // 정확히 계산하기 위해 버림 사용 (올림을 하면 실제보다 한 프레임 더 많을 수 있음)
            m_frameCount = std::floor(m_duration * m_fps);
            qDebug() << "Calculated frame count:" << m_frameCount 
                     << "(duration:" << m_duration << "× fps:" << m_fps << ")";
        }
        
        // 최소값은 1프레임으로 설정
        m_frameCount = std::max(1, m_frameCount);
        
        // 프레임 오프셋 적용 (0 또는 1 기반 설정)
        int displayedFrameCount = m_oneBasedFrameNumbers ? m_frameCount : m_frameCount - 1;
        
        // 0 기반일 때는 마지막 프레임 번호가 전체 - 1
        qDebug() << "Final frame count:" << m_frameCount 
                 << "(Displayed as: 0-" << displayedFrameCount << ")";
        
        // 프레임 카운트 변경 신호 발생
        emit frameCountChanged(m_frameCount);
        
    } catch (const std::exception& e) {
        qCritical() << "Error updating frame count:" << e.what();
    } catch (...) {
        qCritical() << "Unknown error updating frame count";
    }
}

// 프레임 번호 체계 설정 함수 (0-기반 또는 1-기반)
void MpvObject::setOneBasedFrameNumbers(bool oneBased)
{
    if (m_oneBasedFrameNumbers != oneBased) {
        m_oneBasedFrameNumbers = oneBased;
        emit oneBasedFrameNumbersChanged(oneBased);
        
        // 프레임 카운트도 업데이트 (표시 방식이 변경됨)
        updateFrameCount();
    }
}

// 프레임 번호 체계 확인 함수
bool MpvObject::isOneBasedFrameNumbers() const
{
    return m_oneBasedFrameNumbers;
}

// 총 프레임 수 반환 함수
int MpvObject::frameCount() const
{
    return m_frameCount;
}

void MpvObject::applyVideoFilters(const QStringList& filters)
{
    if (!mpv)
        return;

    command(QVariantList() << "vf" << "clr");
    for (const QString &f : filters) {
        command(QVariantList() << "vf" << "add" << f);
    }
}
