class VideoScopeItem : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(QVariant mpvObject READ mpvObject WRITE setMpvObject NOTIFY mpvObjectChanged)
    Q_PROPERTY(int scopeType READ scopeType WRITE setScopeType NOTIFY scopeTypeChanged)
    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int intensity READ intensity WRITE setIntensity NOTIFY intensityChanged)
    Q_PROPERTY(bool logarithmic READ logarithmic WRITE setLogarithmic NOTIFY logarithmicChanged)
    Q_PROPERTY(int mode READ mode WRITE setMode NOTIFY modeChanged)
    
public:
    VideoScopeItem(QQuickItem* parent = nullptr);
    ~VideoScopeItem();
    
    QQuickFramebufferObject::Renderer* createRenderer() const override;
    
    QVariant mpvObject() const { return m_mpvObject; }
    void setMpvObject(const QVariant& obj);
    
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
    
    mpv_handle* getMpvHandle() const;
    
public slots:
    void updateFrameData();
    void handleFrameSwap();
    void handleMpvEvents();
    
signals:
    void mpvObjectChanged();
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
    
    QVariant m_mpvObject;
    MpvObject* m_mpv;
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