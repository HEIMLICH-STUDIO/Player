#include "TimecodeUtils.h"
#include <QRegularExpression>
#include <QStringList>
#include <QDebug>
#include <cmath>

QString TimecodeUtils::frameToTimecode(int frame, double fps, TimecodeFormat format)
{
    if (fps <= 0) return "00:00:00:00";
    
    switch (format) {
        case SMPTE_NON_DROP:
            return frameToSMPTE(frame, fps, false);
        case SMPTE_DROP_FRAME:
            return frameToSMPTE(frame, fps, true);
        case HH_MM_SS_MS:
            return frameToHMSMS(frame, fps);
        case FRAMES_ONLY:
            return QString::number(frame);
        case CUSTOM:
            return frameToCustom(frame, fps, "%H:%M:%S.%f");
        default:
            return frameToSMPTE(frame, fps, false);
    }
}

QString TimecodeUtils::frameToSMPTE(int frame, double fps, bool dropFrame)
{
    if (fps <= 0) return "00:00:00:00";
    
    int totalFrames = frame;
    
    // Drop frame 계산 (29.97fps, 59.94fps 등)
    if (dropFrame && (std::abs(fps - 29.97) < 0.1 || std::abs(fps - 59.94) < 0.1)) {
        totalFrames = frameToDropFrame(frame, fps);
    }
    
    int framesPerSecond = static_cast<int>(std::round(fps));
    int framesPerMinute = framesPerSecond * 60;
    int framesPerHour = framesPerMinute * 60;
    
    int hours = totalFrames / framesPerHour;
    totalFrames %= framesPerHour;
    
    int minutes = totalFrames / framesPerMinute;
    totalFrames %= framesPerMinute;
    
    int seconds = totalFrames / framesPerSecond;
    int frames = totalFrames % framesPerSecond;
    
    QString separator = dropFrame ? ";" : ":";
    
    return QString("%1:%2:%3%4%5")
            .arg(hours, 2, 10, QChar('0'))
            .arg(minutes, 2, 10, QChar('0'))
            .arg(seconds, 2, 10, QChar('0'))
            .arg(separator)
            .arg(frames, 2, 10, QChar('0'));
}

QString TimecodeUtils::frameToHMSMS(int frame, double fps)
{
    if (fps <= 0) return "00:00:00.000";
    
    double totalSeconds = frame / fps;
    
    int hours = static_cast<int>(totalSeconds / 3600);
    totalSeconds -= hours * 3600;
    
    int minutes = static_cast<int>(totalSeconds / 60);
    totalSeconds -= minutes * 60;
    
    int seconds = static_cast<int>(totalSeconds);
    int milliseconds = static_cast<int>((totalSeconds - seconds) * 1000);
    
    return QString("%1:%2:%3.%4")
            .arg(hours, 2, 10, QChar('0'))
            .arg(minutes, 2, 10, QChar('0'))
            .arg(seconds, 2, 10, QChar('0'))
            .arg(milliseconds, 3, 10, QChar('0'));
}

QString TimecodeUtils::frameToCustom(int frame, double fps, const QString& pattern)
{
    if (fps <= 0 || frame < 0) return pattern;
    
    double totalSeconds = frame / fps;
    int hours = static_cast<int>(totalSeconds / 3600);
    totalSeconds -= hours * 3600;
    
    int minutes = static_cast<int>(totalSeconds / 60);
    totalSeconds -= minutes * 60;
    
    int seconds = static_cast<int>(totalSeconds);
    double fractionalSeconds = totalSeconds - seconds;
    
    QString result = pattern;
    result.replace("%H", QString("%1").arg(hours, 2, 10, QChar('0')));
    result.replace("%M", QString("%1").arg(minutes, 2, 10, QChar('0')));
    result.replace("%S", QString("%1").arg(seconds, 2, 10, QChar('0')));
    result.replace("%f", QString("%1").arg(static_cast<int>(fractionalSeconds * 1000), 3, 10, QChar('0')));
    result.replace("%F", QString("%1").arg(frame));
    
    return result;
}

int TimecodeUtils::timecodeToFrame(const QString& timecode, double fps, TimecodeFormat format)
{
    if (fps <= 0) return 0;
    
    switch (format) {
        case SMPTE_NON_DROP:
            return SMPTEToFrame(timecode, fps, false);
        case SMPTE_DROP_FRAME:
            return SMPTEToFrame(timecode, fps, true);
        case HH_MM_SS_MS:
            return HMSMSToFrame(timecode, fps);
        case FRAMES_ONLY:
            return timecode.toInt();
        case CUSTOM:
            // 커스텀 포맷은 기본 SMPTE로 처리
            return SMPTEToFrame(timecode, fps, false);
        default:
            return SMPTEToFrame(timecode, fps, false);
    }
}

int TimecodeUtils::SMPTEToFrame(const QString& timecode, double fps, bool dropFrame)
{
    if (!isValidSMPTE(timecode) || fps <= 0) return 0;
    
    // SMPTE 형식 파싱: HH:MM:SS:FF 또는 HH:MM:SS;FF
    QRegularExpression regex(R"((\d{2}):(\d{2}):(\d{2})[:;](\d{2}))");
    QRegularExpressionMatch match = regex.match(timecode);
    
    if (!match.hasMatch()) return 0;
    
    int hours = match.captured(1).toInt();
    int minutes = match.captured(2).toInt();
    int seconds = match.captured(3).toInt();
    int frames = match.captured(4).toInt();
    
    int framesPerSecond = static_cast<int>(std::round(fps));
    int totalFrames = (hours * 3600 + minutes * 60 + seconds) * framesPerSecond + frames;
    
    // Drop frame 보정
    if (dropFrame && (std::abs(fps - 29.97) < 0.1 || std::abs(fps - 59.94) < 0.1)) {
        totalFrames = dropFrameToFrame(totalFrames, fps);
    }
    
    return totalFrames;
}

int TimecodeUtils::HMSMSToFrame(const QString& timecode, double fps)
{
    if (!isValidHMSMS(timecode) || fps <= 0) return 0;
    
    // HH:MM:SS.mmm 형식 파싱
    QRegularExpression regex(R"((\d{2}):(\d{2}):(\d{2})\.(\d{3}))");
    QRegularExpressionMatch match = regex.match(timecode);
    
    if (!match.hasMatch()) return 0;
    
    int hours = match.captured(1).toInt();
    int minutes = match.captured(2).toInt();
    int seconds = match.captured(3).toInt();
    int milliseconds = match.captured(4).toInt();
    
    double totalSeconds = hours * 3600 + minutes * 60 + seconds + milliseconds / 1000.0;
    
    return static_cast<int>(totalSeconds * fps);
}

QString TimecodeUtils::positionToTimecode(double position, double fps, TimecodeFormat format)
{
    if (fps <= 0) return "00:00:00:00";
    
    int frame = static_cast<int>(position * fps);
    return frameToTimecode(frame, fps, format);
}

double TimecodeUtils::timecodeToPosition(const QString& timecode, double fps, TimecodeFormat format)
{
    if (fps <= 0) return 0.0;
    
    int frame = timecodeToFrame(timecode, fps, format);
    return frame / fps;
}

QString TimecodeUtils::extractEmbeddedTimecode(AVFrame* frame)
{
    if (!frame) return QString();
    
    // FFmpeg 프레임에서 타임코드 메타데이터 추출
    AVDictionary* metadata = frame->metadata;
    if (!metadata) return QString();
    
    AVDictionaryEntry* entry = av_dict_get(metadata, "timecode", nullptr, 0);
    if (entry) {
        return QString(entry->value);
    }
    
    return QString();
}

bool TimecodeUtils::hasEmbeddedTimecode(AVFrame* frame)
{
    return !extractEmbeddedTimecode(frame).isEmpty();
}

bool TimecodeUtils::isDropFrame(double fps)
{
    // 일반적인 drop frame 프레임 레이트들
    return (std::abs(fps - 29.97) < 0.1 || 
            std::abs(fps - 59.94) < 0.1 ||
            std::abs(fps - 23.976) < 0.1);
}

bool TimecodeUtils::isValidTimecode(const QString& timecode, TimecodeFormat format)
{
    switch (format) {
        case SMPTE_NON_DROP:
        case SMPTE_DROP_FRAME:
            return isValidSMPTE(timecode);
        case HH_MM_SS_MS:
            return isValidHMSMS(timecode);
        case FRAMES_ONLY:
            return timecode.toInt() >= 0;
        case CUSTOM:
            return !timecode.isEmpty();
        default:
            return false;
    }
}

bool TimecodeUtils::isValidSMPTE(const QString& timecode)
{
    QRegularExpression regex(R"(^\d{2}:\d{2}:\d{2}[:;]\d{2}$)");
    return regex.match(timecode).hasMatch();
}

bool TimecodeUtils::isValidHMSMS(const QString& timecode)
{
    QRegularExpression regex(R"(^\d{2}:\d{2}:\d{2}\.\d{3}$)");
    return regex.match(timecode).hasMatch();
}

TimecodeUtils::TimecodeFormat TimecodeUtils::detectFormat(const QString& timecode)
{
    if (isValidSMPTE(timecode)) {
        return timecode.contains(';') ? SMPTE_DROP_FRAME : SMPTE_NON_DROP;
    } else if (isValidHMSMS(timecode)) {
        return HH_MM_SS_MS;
    } else if (timecode.toInt() >= 0 && timecode == QString::number(timecode.toInt())) {
        return FRAMES_ONLY;
    } else {
        return CUSTOM;
    }
}

QString TimecodeUtils::formatTimecode(int hours, int minutes, int seconds, int frames, TimecodeFormat format)
{
    switch (format) {
        case SMPTE_NON_DROP:
            return QString("%1:%2:%3:%4")
                    .arg(hours, 2, 10, QChar('0'))
                    .arg(minutes, 2, 10, QChar('0'))
                    .arg(seconds, 2, 10, QChar('0'))
                    .arg(frames, 2, 10, QChar('0'));
        case SMPTE_DROP_FRAME:
            return QString("%1:%2:%3;%4")
                    .arg(hours, 2, 10, QChar('0'))
                    .arg(minutes, 2, 10, QChar('0'))
                    .arg(seconds, 2, 10, QChar('0'))
                    .arg(frames, 2, 10, QChar('0'));
        case HH_MM_SS_MS:
            return QString("%1:%2:%3.%4")
                    .arg(hours, 2, 10, QChar('0'))
                    .arg(minutes, 2, 10, QChar('0'))
                    .arg(seconds, 2, 10, QChar('0'))
                    .arg(frames * 1000 / 30, 3, 10, QChar('0')); // 30fps 기준 ms 변환
        case FRAMES_ONLY:
            return QString::number(hours * 108000 + minutes * 1800 + seconds * 30 + frames); // 30fps 기준
        default:
            return QString("%1:%2:%3:%4")
                    .arg(hours, 2, 10, QChar('0'))
                    .arg(minutes, 2, 10, QChar('0'))
                    .arg(seconds, 2, 10, QChar('0'))
                    .arg(frames, 2, 10, QChar('0'));
    }
}

void TimecodeUtils::parseTimecode(const QString& timecode, int& hours, int& minutes, int& seconds, int& frames, TimecodeFormat format)
{
    hours = minutes = seconds = frames = 0;
    
    switch (format) {
        case SMPTE_NON_DROP:
        case SMPTE_DROP_FRAME: {
            QRegularExpression regex(R"((\d{2}):(\d{2}):(\d{2})[:;](\d{2}))");
            QRegularExpressionMatch match = regex.match(timecode);
            if (match.hasMatch()) {
                hours = match.captured(1).toInt();
                minutes = match.captured(2).toInt();
                seconds = match.captured(3).toInt();
                frames = match.captured(4).toInt();
            }
            break;
        }
        case HH_MM_SS_MS: {
            QRegularExpression regex(R"((\d{2}):(\d{2}):(\d{2})\.(\d{3}))");
            QRegularExpressionMatch match = regex.match(timecode);
            if (match.hasMatch()) {
                hours = match.captured(1).toInt();
                minutes = match.captured(2).toInt();
                seconds = match.captured(3).toInt();
                frames = match.captured(4).toInt() * 30 / 1000; // ms를 프레임으로 변환 (30fps 기준)
            }
            break;
        }
        case FRAMES_ONLY: {
            int totalFrames = timecode.toInt();
            hours = totalFrames / 108000; // 30fps * 3600초
            totalFrames %= 108000;
            minutes = totalFrames / 1800; // 30fps * 60초
            totalFrames %= 1800;
            seconds = totalFrames / 30;
            frames = totalFrames % 30;
            break;
        }
        default:
            break;
    }
}

// Drop Frame 계산 헬퍼 함수들
int TimecodeUtils::frameToDropFrame(int frame, double fps)
{
    if (!isDropFrame(fps)) return frame;
    
    // 29.97fps drop frame 계산
    if (std::abs(fps - 29.97) < 0.1) {
        int framesPerMinute = 1800; // 30 * 60
        int dropFrames = 2; // 매분 2프레임 드롭
        
        int minutes = frame / framesPerMinute;
        int remainingFrames = frame % framesPerMinute;
        
        // 10분마다는 드롭하지 않음
        int tenMinutes = minutes / 10;
        int remainingMinutes = minutes % 10;
        
        int droppedFrames = tenMinutes * 18 + remainingMinutes * dropFrames;
        
        return frame - droppedFrames;
    }
    
    return frame;
}

int TimecodeUtils::dropFrameToFrame(int dropFrame, double fps)
{
    if (!isDropFrame(fps)) return dropFrame;
    
    // 29.97fps drop frame 역계산
    if (std::abs(fps - 29.97) < 0.1) {
        int framesPerMinute = 1798; // 1800 - 2 (drop frames)
        int framesPerTenMinutes = 17982; // 18000 - 18 (drop frames)
        
        int tenMinutes = dropFrame / framesPerTenMinutes;
        int remainingFrames = dropFrame % framesPerTenMinutes;
        
        int minutes = remainingFrames / framesPerMinute;
        int frames = remainingFrames % framesPerMinute;
        
        int totalMinutes = tenMinutes * 10 + minutes;
        int droppedFrames = tenMinutes * 18 + minutes * 2;
        
        return dropFrame + droppedFrames;
    }
    
    return dropFrame;
}

bool TimecodeUtils::matchesPattern(const QString& timecode, const QString& pattern)
{
    Q_UNUSED(timecode)
    Q_UNUSED(pattern)
    // 패턴 매칭 로직 (향후 구현)
    return false;
} 