#ifndef TIMECODEUTILS_H
#define TIMECODEUTILS_H

#include <QString>

extern "C" {
#include <libavformat/avformat.h>
#include <libavutil/frame.h>
#include <libavutil/dict.h>
}

class TimecodeUtils
{
public:
    enum TimecodeFormat {
        SMPTE_NON_DROP = 0,
        SMPTE_DROP_FRAME = 1,
        HH_MM_SS_MS = 2,
        FRAMES_ONLY = 3,
        CUSTOM = 4
    };
    // 프레임을 타임코드로 변환
    static QString frameToTimecode(int frame, double fps, TimecodeFormat format = SMPTE_NON_DROP);
    static QString frameToSMPTE(int frame, double fps, bool dropFrame = false);
    static QString frameToHMSMS(int frame, double fps);
    static QString frameToCustom(int frame, double fps, const QString& pattern);
    
    // 타임코드를 프레임으로 변환
    static int timecodeToFrame(const QString& timecode, double fps, TimecodeFormat format = SMPTE_NON_DROP);
    static int SMPTEToFrame(const QString& timecode, double fps, bool dropFrame = false);
    static int HMSMSToFrame(const QString& timecode, double fps);
    
    // 시간 위치와 타임코드 변환
    static QString positionToTimecode(double position, double fps, TimecodeFormat format = SMPTE_NON_DROP);
    static double timecodeToPosition(const QString& timecode, double fps, TimecodeFormat format = SMPTE_NON_DROP);
    
    // FFmpeg 프레임에서 타임코드 추출
    static QString extractEmbeddedTimecode(AVFrame* frame);
    static bool hasEmbeddedTimecode(AVFrame* frame);
    
    // 유틸리티 함수들
    static bool isDropFrame(double fps);
    static bool isValidTimecode(const QString& timecode, TimecodeFormat format = SMPTE_NON_DROP);
    static bool isValidSMPTE(const QString& timecode);
    static bool isValidHMSMS(const QString& timecode);
    
    // 타임코드 포맷팅
    static QString formatTimecode(int hours, int minutes, int seconds, int frames, TimecodeFormat format = SMPTE_NON_DROP);
    static void parseTimecode(const QString& timecode, int& hours, int& minutes, int& seconds, int& frames, TimecodeFormat format = SMPTE_NON_DROP);
    
private:
    // Drop Frame 계산
    static int frameToDropFrame(int frame, double fps);
    static int dropFrameToFrame(int dropFrame, double fps);
};

#endif // TIMECODEUTILS_H 