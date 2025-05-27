bool VideoScopeItem::extractCurrentFrame()
{
    if (!m_ffmpeg)
        return false;
    
    QMutexLocker locker(&m_frameMutex);
    
    // 1. FFmpeg의 현재 프레임 크기 확인
    QVariant widthVar = m_ffmpeg->getProperty("width");
    QVariant heightVar = m_ffmpeg->getProperty("height");
    
    if (!widthVar.isValid() || !heightVar.isValid())
        return false;
    
    int width = widthVar.toInt();
    int height = heightVar.toInt();
    
    if (width <= 0 || height <= 0)
        return false;
    
    // 성능을 위해 스코프 렌더링 해상도 제한
    int targetWidth = qMin(640, width);
    int targetHeight = qMin(360, height);
    
    // 버퍼 크기가 다르면 재할당
    if (m_dataWidth != targetWidth || m_dataHeight != targetHeight) {
        delete[] m_frameData;
        m_frameData = new unsigned char[targetWidth * targetHeight * 4]; // RGBA
        m_dataWidth = targetWidth;
        m_dataHeight = targetHeight;
    }
    
    // MPV API를 통한 프레임 데이터 추출은 현재 사용할 수 없음
    // 대신 더 향상된 테스트 패턴 생성
    try {
        // 비디오가 재생 중인지 확인
        QVariant pausedVar = m_ffmpeg->getProperty("paused");
        bool isPaused = pausedVar.toBool();
        
        // 현재 재생 시간 가져오기
        QVariant posVar = m_ffmpeg->getProperty("position");
        double position = posVar.isValid() ? posVar.toDouble() : 0.0;
        
        // 향상된 테스트 패턴 생성
        float time = position + QDateTime::currentMSecsSinceEpoch() / 10000.0f;
        
        for (int y = 0; y < targetHeight; y++) {
            for (int x = 0; x < targetWidth; x++) {
                int index = (y * targetWidth + x) * 4;
                
                // 정규화된 좌표
                float nx = (float)x / targetWidth;
                float ny = (float)y / targetHeight;
                float cx = nx - 0.5f;
                float cy = ny - 0.5f;
                float dist = sqrt(cx*cx + cy*cy) * 2.0f;
                
                // 재생 상태에 따라 다른 테스트 패턴 생성
                if (isPaused) {
                    // 일시정지 상태: 색상환 패턴
                    float angle = atan2(cy, cx);
                    float hue = (angle / (2 * M_PI)) + 0.5f;
                    
                    // HSV -> RGB 변환 (간단한 버전)
                    float r, g, b;
                    HSVtoRGB(hue, 1.0f - dist, 0.8f, r, g, b);
                    
                    m_frameData[index] = static_cast<unsigned char>(r * 255);     // R
                    m_frameData[index+1] = static_cast<unsigned char>(g * 255);   // G
                    m_frameData[index+2] = static_cast<unsigned char>(b * 255);   // B
                } else {
                    // 재생 중: 움직이는 패턴
                    float freq = 6.0f;
                    float wave = (sin(nx * freq + time) * 0.5f + 0.5f) * (cos(ny * freq + time * 1.5f) * 0.5f + 0.5f);
                    
                    // 그라데이션 색상
                    m_frameData[index] = static_cast<unsigned char>((cos(time * 0.3f) * 0.5f + 0.5f) * 255 * wave);                      // R
                    m_frameData[index+1] = static_cast<unsigned char>((sin(time * 0.5f + M_PI/3) * 0.5f + 0.5f) * 255 * (1.0f-wave));    // G
                    m_frameData[index+2] = static_cast<unsigned char>((sin(time * 0.7f + 2*M_PI/3) * 0.5f + 0.5f) * 255);                // B
                }
                
                m_frameData[index+3] = 255;  // A
            }
        }
    }
    catch (const std::exception& e) {
        qWarning() << "Exception in extractCurrentFrame:" << e.what();
        return false;
    }
    
    return true;
}

// HSV -> RGB 변환 헬퍼 함수
void VideoScopeItem::HSVtoRGB(float h, float s, float v, float &r, float &g, float &b)
{
    int i = floor(h * 6);
    float f = h * 6 - i;
    float p = v * (1 - s);
    float q = v * (1 - f * s);
    float t = v * (1 - (1 - f) * s);
    
    switch(i % 6) {
        case 0: r = v; g = t; b = p; break;
        case 1: r = q; g = v; b = p; break;
        case 2: r = p; g = v; b = t; break;
        case 3: r = p; g = q; b = v; break;
        case 4: r = t; g = p; b = v; break;
        case 5: r = v; g = p; b = q; break;
    }
} 