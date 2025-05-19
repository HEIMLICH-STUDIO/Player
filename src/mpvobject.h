#ifndef MPVOBJECT_H
#define MPVOBJECT_H

#include <QtQuick/QQuickFramebufferObject>
#include <client.h>
#include <render_gl.h>
#include <QTimer>
#include <QVariant>

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(QString filename READ filename NOTIFY filenameChanged)
    Q_PROPERTY(bool pause READ isPaused NOTIFY pauseChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY mediaTitleChanged)

    mpv_handle *mpv;
    mpv_render_context *mpv_context;
    friend class MpvRenderer;

    QString m_filename;
    QString m_mediaTitle;
    bool m_pause = false;
    double m_position = 0;
    double m_duration = 0;

public:
    MpvObject(QQuickItem *parent = nullptr);
    virtual ~MpvObject();

    QString filename() const { return m_filename; }
    QString mediaTitle() const { return m_mediaTitle; }
    bool isPaused() const { return m_pause; }
    double position() const { return m_position; }
    double duration() const { return m_duration; }

    QQuickFramebufferObject::Renderer *createRenderer() const override;

    // 커맨드 및 속성 처리 함수
    Q_INVOKABLE void command(const QVariant& params);
    Q_INVOKABLE void setProperty(const QString& name, const QVariant& value);
    Q_INVOKABLE QVariant getProperty(const QString& name);

signals:
    void filenameChanged(QString filename);
    void mediaTitleChanged(QString title);
    void pauseChanged(bool pause);
    void positionChanged(double position);
    void durationChanged(double duration);
    void playingChanged(bool playing);
    void onUpdate();
    void videoReconfig();

public slots:
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void playPause();
    
private slots:
    void handleMpvEvents();

private:
    // MPV 노드 변환 헬퍼 함수
    mpv_node createNode(const QVariant& v);
    void freeNode(mpv_node* node);
    QVariant fromNode(const mpv_node& node);
};

#endif // MPVOBJECT_H 