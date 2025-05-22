#include "mpvobject.h"
#include <stdexcept>
#include <QtQuick/QQuickWindow>
#include <QtGui/QOpenGLContext>
#include <QtOpenGL/QOpenGLFramebufferObject>
#include <QtGui/QOpenGLFunctions>
#include <QDebug>
#include <QDateTime>
#include <QElapsedTimer>
#include <QRegularExpression>

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
            obj->update();
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
    
    // 코덱 정보 감시 추가
    mpv_observe_property(mpv, 0, "video-codec", MPV_FORMAT_STRING);
    mpv_observe_property(mpv, 0, "video-format", MPV_FORMAT_STRING);
    mpv_observe_property(mpv, 0, "width", MPV_FORMAT_INT64);
    mpv_observe_property(mpv, 0, "height", MPV_FORMAT_INT64);
    
    // Log available properties
    qDebug() << "MPV initialized, setting up event handlers";
    mpv_set_wakeup_callback(mpv, on_mpv_events, this);
    
    if (mpv_initialize(mpv) < 0) {
        qCritical() << "Failed to initialize MPV";
        throw std::runtime_error("Failed to initialize mpv");
    }
    
    // 타이머 초기화
    m_stateChangeTimer = new QTimer(this);
    m_stateChangeTimer->setSingleShot(true);
    m_stateChangeTimer->setInterval(50);
    connect(m_stateChangeTimer, &QTimer::timeout, this, &MpvObject::processStateChange);
    
    m_performanceTimer = new QTimer(this);
    m_performanceTimer->setInterval(5000); // 5초마다 성능 확인
    connect(m_performanceTimer, &QTimer::timeout, this, &MpvObject::checkPerformance);
    m_performanceTimer->start();
    
    // 메타데이터 업데이트 타이머 추가 - 단일 샷으로 변경
    m_metadataTimer = new QTimer(this);
    m_metadataTimer->setSingleShot(true); // 반복 없이 한 번만 실행되도록 변경
    m_metadataTimer->setInterval(500); // 0.5초 후 한 번만 메타데이터 업데이트
    connect(m_metadataTimer, &QTimer::timeout, this, &MpvObject::updateVideoMetadata);
    // 자동 시작 안함 - 파일 로드 시 한 번만 호출됨
    
    // 타임코드 업데이트 타이머 설정
    m_timecodeTimer = new QTimer(this);
    m_timecodeTimer->setInterval(100); // 초당 10회 업데이트 (부드러운 표시)
    connect(m_timecodeTimer, &QTimer::timeout, this, &MpvObject::updateTimecode);
    m_timecodeTimer->start();
    
    // UI를 항상 지연 없이 업데이트
    setFlag(ItemHasContents, true);
    
    qDebug() << "MpvObject constructor completed successfully";
}

MpvObject::~MpvObject()
{
    qDebug() << "MpvObject destructor called";

    if (mpv) {
        // 안전한 종료를 위한 모든 타이머 중지
        if (m_stateChangeTimer) {
            m_stateChangeTimer->stop();
        }
        
        if (m_performanceTimer) {
            m_performanceTimer->stop();
        }
        
        if (m_metadataTimer) {
            m_metadataTimer->stop();
        }
        
        if (m_timecodeTimer) {
            m_timecodeTimer->stop();
        }
        
        // MPV 컨텍스트 정리
        if (mpv_context) {
            mpv_render_context_free(mpv_context);
            mpv_context = nullptr;
        }
        
        // MPV 인스턴스 정리
        mpv_terminate_destroy(mpv);
        mpv = nullptr;
    }
}

QQuickFramebufferObject::Renderer *MpvObject::createRenderer() const
{
    window()->setPersistentSceneGraph(true);
    return new MpvRenderer(const_cast<MpvObject*>(this));
}

void MpvObject::handleMpvEvents()
{
    // mpv 이벤트 루프
    while (mpv) {
        mpv_event *event = mpv_wait_event(mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) {
            break;
        }
        
        switch (event->event_id) {
            case MPV_EVENT_PROPERTY_CHANGE: {
                mpv_event_property *prop = (mpv_event_property *)event->data;
                
                // 모든 속성 변경 로그 출력 (디버깅용)
                // qDebug() << "Property changed:" << prop->name;
                
                if (prop->format == MPV_FORMAT_FLAG) {
                    if (strcmp(prop->name, "pause") == 0) {
                        if (prop->data) {
                            bool pause = *(int *)prop->data;
                            if (m_pause != pause) {
                                m_pause = pause;
                                m_stateChangeTimer->start();
                                emit pauseChanged(m_pause);
                                emit playingChanged(!m_pause);
                            }
                        }
                    }
                    else if (strcmp(prop->name, "eof-reached") == 0) {
                        if (prop->data) {
                            bool eofReached = *(int *)prop->data;
                            if (m_endReached != eofReached) {
                                m_endReached = eofReached;
                                if (m_endReached) {
                                    qDebug() << "End of file reached";
                                    emit endReached();
                                    
                                    // 반복 재생 모드 확인
                                    if (m_loopEnabled) {
                                        qDebug() << "Looping enabled, restarting playback";
                                        mpv_command_string(mpv, "seek 0 absolute");
                                        mpv_command_string(mpv, "set pause no");
                                    }
                                }
                            }
                        }
                    }
                }
                else if (prop->format == MPV_FORMAT_DOUBLE) {
                    if (strcmp(prop->name, "time-pos") == 0) {
                        if (prop->data) {
                            double position = *(double *)prop->data;
                            
                            // 위치가 급격히 변화했는지 확인 (시크)
                            bool isSeek = m_position >= 0 && 
                                         std::abs(position - m_position) > 0.5;
                            
                            m_position = position;
                            emit positionChanged(m_position);
                            
                            if (isSeek) {
                                // 시크 감지
                                m_lastSeekTime = QDateTime::currentMSecsSinceEpoch();
                            }
                        }
                    }
                    else if (strcmp(prop->name, "duration") == 0) {
                        if (prop->data) {
                            double duration = *(double *)prop->data;
                            
                            if (qAbs(m_duration - duration) > 0.1) {
                                m_duration = duration;
                                
                                // 프레임 수 계산
                                if (m_fps > 0) {
                                    updateFrameCount();
                                }
                                
                                emit durationChanged(duration);
                            }
                        }
                    }
                    else if (strcmp(prop->name, "estimated-vf-fps") == 0) {
                        if (prop->data) {
                            double fps = *(double *)prop->data;
                            // FPS 값이 유효하고 이전 값과 다른 경우에만 업데이트
                            if (fps > 0 && qAbs(m_fps - fps) > 0.01) {
                                m_fps = fps;
                                
                                // 프레임 수 업데이트
                                updateFrameCount();
                                
                                emit fpsChanged(m_fps);
                            }
                        }
                    }
                }
                else if (prop->format == MPV_FORMAT_STRING) {
                    if (strcmp(prop->name, "media-title") == 0) {
                        if (prop->data) {
                            QString mediaTitle = QString::fromUtf8(*(char **)prop->data);
                            if (m_mediaTitle != mediaTitle) {
                                m_mediaTitle = mediaTitle;
                                emit mediaTitleChanged(m_mediaTitle);
                            }
                        }
                    }
                    else if (strcmp(prop->name, "filename") == 0) {
                        if (prop->data) {
                            QString filename = QString::fromUtf8(*(char **)prop->data);
                            if (m_filename != filename) {
                                m_filename = filename;
                                emit filenameChanged(m_filename);
                            }
                        }
                    }
                }
                
                break;
            }
            
            case MPV_EVENT_VIDEO_RECONFIG: {
                qDebug() << "Video reconfig event - updating frame count only in paused state";
                
                // 비디오 리컨피그 발생 시 일시정지 상태일 때만 프레임 카운트 업데이트
                if (m_pause) {
                    QTimer::singleShot(500, this, &MpvObject::updateFrameCount);
                }
                
                // 비디오 설정 변경 이벤트 발생
                emit videoReconfig();
                break;
            }
            
            case MPV_EVENT_FILE_LOADED: {
                qDebug() << "File load completed, updating metadata immediately";
                
                // 파일 로드 완료 시 한 번만 메타데이터 업데이트 (타이머 한 번만 실행)
                if (!m_metadataTimer->isActive()) {
                    m_metadataTimer->start();
                }
                
                // 타임코드 초기화 및 내장 타임코드 가져오기
                m_timecode = "00:00:00:00";
                m_embeddedTimecode = "";
                if (m_useEmbeddedTimecode || m_timecodeSource > 0) {
                    QTimer::singleShot(300, this, &MpvObject::fetchEmbeddedTimecode);
                }
                
                QTimer::singleShot(100, this, [this]() {
                    qDebug() << "New file loaded - calculating initial frame count";
                    updateFrameCount();
                    updateTimecode();
                    emit fileLoaded();
                });
                break;
            }
            
            default:
                break;
        }
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
        
        // 중요: 시크 전에 지연 중인 타이머 취소하고 마지막 시크 시간 업데이트
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
        
        qDebug() << "MPV seek to:" << finalSeekPos;
        
        // 1. 먼저 일시정지 설정
        mpv_command_string(mpv, "set pause yes");
        if (!m_pause) {
            m_pause = true;
            emit pauseChanged(true);
            emit playingChanged(false);
        }
        
        // 2. 정확한 시크 수행 (두 가지 방법으로 동시에) - 중요 부분
        // 2.1 MPV 속성 직접 설정 (UI 즉시 반응)
        mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &finalSeekPos);
        
        // 2.2 명령어로 정확한 시크 실행 (더 정밀한 프레임 위치)
        mpv_command_string(mpv, QString("seek %1 absolute exact").arg(finalSeekPos).toUtf8().constData());
        
        // 3. 위치 정보 즉시 업데이트
        m_position = finalSeekPos;
        m_lastPosition = finalSeekPos;
        emit positionChanged(finalSeekPos);
        
        // 4. UI 강제 갱신
        update();
        
        // 5. 프레임 위치 계산 및 시그널 발생
        if (m_fps > 0) {
            int frame = qRound(finalSeekPos * m_fps);
            emit seekRequested(frame);
        }
        
        // 6. 시크 후 정확한 위치 확인을 위한 타이머 (50ms)
        QTimer::singleShot(50, this, [this, finalSeekPos]() {
            try {
                // 시크된 위치 확인
                double verifyPos = finalSeekPos;
                mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &verifyPos);
                
                // 위치 정보 다시 업데이트
                m_position = verifyPos;
                emit positionChanged(verifyPos);
                
                // 프레임 위치 다시 계산 및 시그널 발생
                if (m_fps > 0) {
                    int frame = qRound(verifyPos * m_fps);
                    emit seekRequested(frame);
                }
                
                // 강제 업데이트
                update();
            } catch (...) {
                qWarning() << "Error in first seek verification";
            }
        });
        
        // 7. 두 번째 검증 타이머 (100ms - 더 확실한 검증)
        QTimer::singleShot(150, this, [this, finalSeekPos]() {
            try {
                // 최종 위치 확인
                QVariant posVal = getProperty("time-pos");
                if (posVal.isValid()) {
                    double actualPos = posVal.toDouble();
                    if (std::abs(actualPos - finalSeekPos) > 0.08) {
                        // 위치가 다르면 다시 정확하게 시크
                        double fixPos = finalSeekPos;
                        mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &fixPos);
                        
                        // 위치 정보 다시 업데이트
                        m_position = fixPos;
                        emit positionChanged(fixPos);
                        
                        // 프레임 위치 시그널 재발생
                        if (m_fps > 0) {
                            int frame = qRound(fixPos * m_fps);
                            emit seekRequested(frame);
                        }
                    }
                }
            } catch (...) {
                qWarning() << "Error in second seek verification";
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
        // setProperty 대신 mpv_command_string 직접 사용 (더 안정적)
        if (paused) {
            // 재생 시작
            mpv_command_string(mpv, "set pause no");
            m_pause = false;
        } else {
            // 일시 정지
            mpv_command_string(mpv, "set pause yes");
            m_pause = true;
        }
        // 상태 변경 알림
        emit pauseChanged(m_pause);
        emit playingChanged(!m_pause);
        update();
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
    // 1. 이미 프레임 카운트가 계산되었으면 재계산 안 함 (영상 변경 시에만 계산)
    static bool frameCounted = false;
    if (frameCounted && m_frameCount > 0) {
        qDebug() << "Frame count already calculated - preventing duplicate updates";
        return;
    }
    
    // 2. 기본 검증
    if (!mpv || m_filename.isEmpty() || m_duration <= 0 || m_fps <= 0) {
        qDebug() << "Failed to calculate frame count: missing required data";
        return;
    }
    
    // 3. 드래그/시크 중에는 업데이트 방지
    QVariant blocked = false;
    try {
        QObject* parent = this->parent();
        while (parent) {
            if (parent->metaObject()->className() == QStringLiteral("QQuickItem") || 
                QString(parent->metaObject()->className()).contains("VideoArea")) {
                
                blocked = parent->property("metadataUpdateBlocked");
                if (blocked.isValid() && blocked.toBool()) {
                    qDebug() << "Metadata blocked - skipping frame count update";
                    return;
                }
                break;
            }
            parent = parent->parent();
        }
    } catch (...) {
        // 무시하고 계속 진행
    }
    
    // 4. 시크 직후에는 업데이트 방지
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (m_lastSeekTime > 0 && (now - m_lastSeekTime) < 2000) {
        qDebug() << "Within 2 seconds after seek - skipping frame count update";
        return;
    }
    
    // 실제 프레임 카운트 계산 수행
    try {
        qDebug() << "Updating frame count...";
        
        // MPV에서 직접 프레임 수 가져오기
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
        // 프레임 수 계산 방식 3: 지속 시간 * FPS
        else {
            m_frameCount = std::floor(m_duration * m_fps);
            qDebug() << "Calculated frame count:" << m_frameCount 
                     << "(duration:" << m_duration << "× fps:" << m_fps << ")";
        }
        
        // 최소값은 1프레임
        m_frameCount = std::max(1, m_frameCount);
        
        // 프레임 오프셋 적용
        int displayedFrameCount = m_oneBasedFrameNumbers ? m_frameCount : m_frameCount - 1;
        
        qDebug() << "Final frame count:" << m_frameCount 
                 << "(Displayed as: 0-" << displayedFrameCount << ")";
        
        // 이미 계산 완료 표시
        frameCounted = true;
        
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

// 코덱 정보 접근자 구현
QString MpvObject::videoCodec() const
{
    return m_videoCodec;
}

QString MpvObject::videoFormat() const
{
    return m_videoFormat;
}

QString MpvObject::videoResolution() const
{
    return m_videoResolution;
}

// 메타데이터 업데이트 함수 구현
void MpvObject::updateVideoMetadata()
{
    if (!mpv) return;
    
    // 메타데이터 업데이트가 차단된 상태인지 확인 - 강화된 검사
    QVariant blocked = false;
    try {
        // 1. 직접 부모 객체에서 플래그 확인
        QObject* parent = this->parent();
        while (parent) {
            if (parent->metaObject()->className() == QStringLiteral("QQuickItem") || 
                QString(parent->metaObject()->className()).contains("VideoArea")) {
                
                blocked = parent->property("metadataUpdateBlocked");
                if (blocked.isValid() && blocked.toBool()) {
                    qDebug() << "Metadata update blocked - skipping update";
                    return;
                }
                break;
            }
            parent = parent->parent();
        }
    } catch (...) {
        // 무시하고 계속 진행
    }
    
    // 2. 재생 중인지 확인 - 재생 중이면 메타데이터 업데이트 차단
    if (!m_pause) {
        qDebug() << "Video is playing - skipping metadata update";
        return;
    }
    
    // 3. 시크 직후에는 업데이트 방지 (5초 이내로 확장)
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (m_lastSeekTime > 0 && (now - m_lastSeekTime) < 5000) {
        qDebug() << "Within 5 seconds after seek - skipping metadata update";
        return;
    }
    
    // 4. 초기 로드 후 메타데이터가 이미 업데이트된 경우 불필요한 업데이트 방지
    static bool metadataAlreadyUpdated = false;
    if (metadataAlreadyUpdated && !m_filename.isEmpty()) {
        static QString lastProcessedFile = "";
        if (lastProcessedFile == m_filename) {
            qDebug() << "Metadata already processed for this file - skipping redundant update";
            return;
        }
    }
    
    qDebug() << "Starting metadata update - file:" << m_filename;
    
    try {
        // 비디오 코덱 정보 가져오기
        QVariant codecVar = getProperty("video-codec");
        if (codecVar.isValid() && !codecVar.toString().isEmpty()) {
            QString newCodec = codecVar.toString();
            if (m_videoCodec != newCodec) {
                m_videoCodec = newCodec;
                emit videoCodecChanged(m_videoCodec);
                qDebug() << "Video codec updated:" << m_videoCodec;
            }
        }
        
        // 비디오 포맷 정보 가져오기
        QVariant formatVar = getProperty("video-format");
        if (formatVar.isValid() && !formatVar.toString().isEmpty()) {
            QString newFormat = formatVar.toString();
            if (m_videoFormat != newFormat) {
                m_videoFormat = newFormat;
                emit videoFormatChanged(m_videoFormat);
                qDebug() << "Video format updated:" << m_videoFormat;
            }
        }
        
        // 비디오 해상도 정보 계산
        QVariant widthVar = getProperty("width");
        QVariant heightVar = getProperty("height");
        if (widthVar.isValid() && heightVar.isValid()) {
            int width = widthVar.toInt();
            int height = heightVar.toInt();
            if (width > 0 && height > 0) {
                QString newResolution = QString("%1×%2").arg(width).arg(height);
                if (m_videoResolution != newResolution) {
                    m_videoResolution = newResolution;
                    emit videoResolutionChanged(m_videoResolution);
                    qDebug() << "Video resolution updated:" << m_videoResolution;
                }
            }
        }
        
        // 메타데이터 변경 시그널 발생
        emit videoMetadataChanged();
        qDebug() << "Metadata update completed - one-time update successful";
        
        // 한 번 업데이트 완료 후 타이머 중지 (반복 방지)
        if (m_metadataTimer->isActive() && !m_metadataTimer->isSingleShot()) {
            m_metadataTimer->stop();
        }
        
        // 현재 파일에 대한 메타데이터 업데이트 완료 표시
        metadataAlreadyUpdated = true;
        static QString lastProcessedFile = m_filename;
        
    } catch (const std::exception& e) {
        qWarning() << "Error updating video metadata:" << e.what();
    } catch (...) {
        qWarning() << "Unknown error updating video metadata";
    }
}

// 타임코드 관련 접근자/설정자 구현
QString MpvObject::timecode() const
{
    return m_timecode;
}

int MpvObject::timecodeFormat() const
{
    return m_timecodeFormat;
}

void MpvObject::setTimecodeFormat(int format)
{
    if (m_timecodeFormat != format && format >= 0 && format <= 4) {
        m_timecodeFormat = format;
        updateTimecode();
        emit timecodeFormatChanged(format);
    }
}

bool MpvObject::useEmbeddedTimecode() const
{
    return m_useEmbeddedTimecode;
}

void MpvObject::setUseEmbeddedTimecode(bool use)
{
    if (m_useEmbeddedTimecode != use) {
        m_useEmbeddedTimecode = use;
        if (use) {
            fetchEmbeddedTimecode();
        } else {
            updateTimecode();
        }
        emit useEmbeddedTimecodeChanged(use);
    }
}

QString MpvObject::embeddedTimecode() const
{
    return m_embeddedTimecode;
}

int MpvObject::timecodeOffset() const
{
    return m_timecodeOffset;
}

void MpvObject::setTimecodeOffset(int offset)
{
    if (m_timecodeOffset != offset) {
        m_timecodeOffset = offset;
        updateTimecode();
        emit timecodeOffsetChanged(offset);
    }
}

QString MpvObject::customTimecodePattern() const
{
    return m_customTimecodePattern;
}

void MpvObject::setCustomTimecodePattern(const QString& pattern)
{
    if (m_customTimecodePattern != pattern && !pattern.isEmpty()) {
        m_customTimecodePattern = pattern;
        if (m_timecodeFormat == 4) { // 커스텀 포맷인 경우
            updateTimecode();
        }
        emit customTimecodePatternChanged(pattern);
    }
}

int MpvObject::timecodeSource() const
{
    return m_timecodeSource;
}

void MpvObject::setTimecodeSource(int source)
{
    if (m_timecodeSource != source && source >= 0 && source <= 3) {
        m_timecodeSource = source;
        updateTimecode();
        emit timecodeSourceChanged(source);
    }
}

// 타임코드 업데이트 함수
void MpvObject::updateTimecode()
{
    if (!mpv || m_fps <= 0 || m_position < 0)
        return;
    
    // 현재 프레임 계산
    int currentFrame = qRound(m_position * m_fps) + m_timecodeOffset;
    
    // 내장 타임코드 사용 설정 확인
    if (m_useEmbeddedTimecode && !m_embeddedTimecode.isEmpty()) {
        QString newTimecode = m_embeddedTimecode;
        emit timecodeChanged(newTimecode);
        return;
    }
    
    // 타임코드 소스에 따라 분기
    if (m_timecodeSource > 0) {
        // 1=Embedded SMPTE, 2=File Metadata, 3=Reel Name
        fetchEmbeddedTimecode();
        if (!m_embeddedTimecode.isEmpty()) {
            emit timecodeChanged(m_embeddedTimecode);
            return;
        }
    }
    
    // 일반 계산 타임코드 (소스가 0이거나 다른 소스에서 타임코드를 가져오지 못한 경우)
    QString newTimecode = frameToTimecode(currentFrame, m_timecodeFormat, m_customTimecodePattern);
    
    if (newTimecode != m_timecode) {
        m_timecode = newTimecode;
        emit timecodeChanged(newTimecode);
    }
}

// 내장 타임코드 추출 함수
void MpvObject::fetchEmbeddedTimecode()
{
    if (!mpv)
        return;
    
    // MPV에서 타임코드 관련 속성 추출 시도
    // 1. SMPTE 타임코드 확인
    char* tc_smpte = mpv_get_property_string(mpv, "chapter-metadata/SMPTE_TIMECODE");
    if (tc_smpte && strlen(tc_smpte) > 0) {
        m_embeddedTimecode = QString(tc_smpte);
        mpv_free(tc_smpte);
        emit embeddedTimecodeChanged(m_embeddedTimecode);
        return;
    }
    if (tc_smpte) mpv_free(tc_smpte);
    
    // 2. 파일 메타데이터에서 타임코드 확인
    char* tc_meta = mpv_get_property_string(mpv, "metadata/timecode");
    if (tc_meta && strlen(tc_meta) > 0) {
        m_embeddedTimecode = QString(tc_meta);
        mpv_free(tc_meta);
        emit embeddedTimecodeChanged(m_embeddedTimecode);
        return;
    }
    if (tc_meta) mpv_free(tc_meta);
    
    // 3. 릴 이름에서 타임코드 확인 (일부 프로페셔널 비디오 파일에서 사용)
    char* reel_tc = mpv_get_property_string(mpv, "metadata/reel_timecode");
    if (reel_tc && strlen(reel_tc) > 0) {
        m_embeddedTimecode = QString(reel_tc);
        mpv_free(reel_tc);
        emit embeddedTimecodeChanged(m_embeddedTimecode);
        return;
    }
    if (reel_tc) mpv_free(reel_tc);
    
    // 내장 타임코드가 없는 경우
    m_embeddedTimecode = "";
    emit embeddedTimecodeChanged(m_embeddedTimecode);
}

// 프레임을 타임코드 문자열로 변환하는 유틸리티 메서드
QString MpvObject::frameToTimecode(int frame, int format, const QString& customPattern) const
{
    if (m_fps <= 0) 
        return "00:00:00:00";
    
    // 기본 형식 사용 (호출자가 지정하지 않았을 경우)
    if (format < 0) {
        format = m_timecodeFormat;
    }
    
    // 프레임 수가 음수인 경우 처리
    bool isNegative = frame < 0;
    frame = abs(frame);
    
    // 총 초 계산
    double totalSeconds = frame / m_fps;
    
    // 시, 분, 초 계산
    int hours = static_cast<int>(totalSeconds / 3600);
    int minutes = static_cast<int>((totalSeconds - hours * 3600) / 60);
    int seconds = static_cast<int>(totalSeconds - hours * 3600 - minutes * 60);
    
    // 프레임 부분 계산
    double fractionalSeconds = totalSeconds - static_cast<int>(totalSeconds);
    int frameNumber = static_cast<int>(fractionalSeconds * m_fps);
    
    // 밀리초 계산 (HH:MM:SS.MS 형식용)
    int milliseconds = static_cast<int>(fractionalSeconds * 1000);
    
    // 타임코드 포맷에 따라 문자열 생성
    QString timecode;
    
    switch (format) {
        case 0: // SMPTE Non-Drop (HH:MM:SS:FF)
            timecode = QString("%1:%2:%3:%4")
                        .arg(hours, 2, 10, QChar('0'))
                        .arg(minutes, 2, 10, QChar('0'))
                        .arg(seconds, 2, 10, QChar('0'))
                        .arg(frameNumber, 2, 10, QChar('0'));
            break;
        
        case 1: // SMPTE Drop-Frame (HH:MM:SS;FF)
            timecode = QString("%1:%2:%3;%4")
                        .arg(hours, 2, 10, QChar('0'))
                        .arg(minutes, 2, 10, QChar('0'))
                        .arg(seconds, 2, 10, QChar('0'))
                        .arg(frameNumber, 2, 10, QChar('0'));
            break;
        
        case 2: // HH:MM:SS.MS (밀리초)
            timecode = QString("%1:%2:%3.%4")
                        .arg(hours, 2, 10, QChar('0'))
                        .arg(minutes, 2, 10, QChar('0'))
                        .arg(seconds, 2, 10, QChar('0'))
                        .arg(milliseconds, 3, 10, QChar('0'));
            break;
        
        case 3: // Frames Only
            timecode = QString::number(frame);
            break;
        
        case 4: // Custom Format
            {
                QString pattern = customPattern.isEmpty() ? m_customTimecodePattern : customPattern;
                
                // 패턴 치환
                timecode = pattern;
                timecode.replace("%H", QString("%1").arg(hours, 2, 10, QChar('0')));
                timecode.replace("%M", QString("%1").arg(minutes, 2, 10, QChar('0')));
                timecode.replace("%S", QString("%1").arg(seconds, 2, 10, QChar('0')));
                timecode.replace("%f", QString("%1").arg(frameNumber, 2, 10, QChar('0')));
                timecode.replace("%t", QString::number(frame));
                timecode.replace("%ms", QString("%1").arg(milliseconds, 3, 10, QChar('0')));
            }
            break;
        
        default:
            timecode = QString("%1:%2:%3:%4")
                        .arg(hours, 2, 10, QChar('0'))
                        .arg(minutes, 2, 10, QChar('0'))
                        .arg(seconds, 2, 10, QChar('0'))
                        .arg(frameNumber, 2, 10, QChar('0'));
    }
    
    // 음수 프레임인 경우 음수 기호 추가
    if (isNegative) {
        timecode = "-" + timecode;
    }
    
    return timecode;
}

// 타임코드 문자열을 프레임 번호로 변환하는 유틸리티 메서드
int MpvObject::timecodeToFrame(const QString& tc) const
{
    if (m_fps <= 0) 
        return 0;
    
    // 타임코드가 단순히 프레임 번호인 경우
    bool ok;
    int frame = tc.toInt(&ok);
    if (ok) return frame;
    
    // 음수 타임코드 처리
    bool isNegative = tc.startsWith("-");
    QString timecode = isNegative ? tc.mid(1) : tc;
    
    // 여러 타임코드 형식 처리
    QRegularExpression reNonDrop("(\\d+):(\\d+):(\\d+):(\\d+)");
    QRegularExpression reDropFrame("(\\d+):(\\d+):(\\d+);(\\d+)");
    QRegularExpression reMilliseconds("(\\d+):(\\d+):(\\d+)\\.(\\d+)");
    
    QRegularExpressionMatch match;
    
    // SMPTE Non-Drop 형식 (HH:MM:SS:FF) 처리
    match = reNonDrop.match(timecode);
    if (match.hasMatch()) {
        int hours = match.captured(1).toInt();
        int minutes = match.captured(2).toInt();
        int seconds = match.captured(3).toInt();
        int frames = match.captured(4).toInt();
        
        int totalFrames = static_cast<int>((hours * 3600 + minutes * 60 + seconds) * m_fps) + frames;
        return isNegative ? -totalFrames : totalFrames;
    }
    
    // SMPTE Drop-Frame 형식 (HH:MM:SS;FF) 처리
    match = reDropFrame.match(timecode);
    if (match.hasMatch()) {
        int hours = match.captured(1).toInt();
        int minutes = match.captured(2).toInt();
        int seconds = match.captured(3).toInt();
        int frames = match.captured(4).toInt();
        
        // 드롭 프레임 보정 (NTSC에 주로 사용)
        int totalMinutes = hours * 60 + minutes;
        int droppedFrames = 0;
        
        if (qFuzzyCompare(m_fps, 29.97) || qFuzzyCompare(m_fps, 30.0)) {
            // 각 10분마다 제외할 프레임 수 계산
            droppedFrames = 2 * (totalMinutes - totalMinutes / 10);
        }
        
        int totalFrames = static_cast<int>((hours * 3600 + minutes * 60 + seconds) * m_fps) + frames - droppedFrames;
        return isNegative ? -totalFrames : totalFrames;
    }
    
    // HH:MM:SS.MS 형식 처리
    match = reMilliseconds.match(timecode);
    if (match.hasMatch()) {
        int hours = match.captured(1).toInt();
        int minutes = match.captured(2).toInt();
        int seconds = match.captured(3).toInt();
        int milliseconds = match.captured(4).toInt();
        
        double fractionalSeconds = milliseconds / 1000.0;
        int frames = static_cast<int>(fractionalSeconds * m_fps);
        
        int totalFrames = static_cast<int>((hours * 3600 + minutes * 60 + seconds) * m_fps) + frames;
        return isNegative ? -totalFrames : totalFrames;
    }
    
    // 지원하지 않는 형식
    return 0;
}
