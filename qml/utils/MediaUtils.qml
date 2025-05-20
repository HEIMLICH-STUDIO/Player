import QtQuick

// 미디어 유틸리티 함수 모음
QtObject {
    id: mediaUtils
    
    // 타임코드 계산 (프레임 -> 타임코드)
    function frameToTimecode(frame, fps) {
        if (frame < 0 || fps <= 0) 
            return "00:00:00:00";
        
        // 프레임에서 시간 계산
        var seconds = frame / fps;
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = Math.floor(seconds % 60);
        var f = Math.floor((frame % fps));
        
        // 포맷팅
        var hh = h.toString().padStart(2, '0');
        var mm = m.toString().padStart(2, '0');
        var ss = s.toString().padStart(2, '0');
        var ff = f.toString().padStart(2, '0');
        
        return hh + ":" + mm + ":" + ss + ":" + ff;
    }
    
    // 타임코드 파싱 (타임코드 -> 프레임)
    function timecodeToFrame(timecode, fps) {
        if (!timecode || fps <= 0) return 0;
        
        // 타임코드 형식 확인 (HH:MM:SS:FF)
        var regex = /(\d{2}):(\d{2}):(\d{2}):(\d{2})/;
        var match = timecode.match(regex);
        
        if (!match)
            return 0;
        
        // 각 부분 추출
        var h = parseInt(match[1]);
        var m = parseInt(match[2]);
        var s = parseInt(match[3]);
        var f = parseInt(match[4]);
        
        // 프레임 계산
        var totalSeconds = h * 3600 + m * 60 + s;
        var totalFrames = Math.floor(totalSeconds * fps) + f;
        
        return totalFrames;
    }
    
    // 파일 경로 정규화 (URL -> 로컬 경로)
    function normalizeFilePath(path) {
        if (!path) return "";
        
        var result = path.toString();
        
        // file:// 프로토콜 제거
        if (result.startsWith("file:///")) {
            // Windows: file:///C:/path/to/file.mp4 -> C:/path/to/file.mp4
            result = result.slice(8);
        }
        
        // URL 디코딩 (공백 등 처리)
        try {
            result = decodeURIComponent(result);
        } catch (e) {
            console.error("Error decoding URI:", e);
        }
        
        return result;
    }
    
    // 파일 확장자 추출
    function getFileExtension(path) {
        if (!path) return "";
        
        var filename = path.toString().split('/').pop();
        var parts = filename.split('.');
        
        return parts.length > 1 ? parts.pop().toLowerCase() : "";
    }
    
    // 비디오 파일 체크
    function isVideoFile(path) {
        var ext = getFileExtension(path);
        var videoExtensions = ["mp4", "avi", "mkv", "mov", "wmv", "flv", "webm"];
        
        return videoExtensions.indexOf(ext) >= 0;
    }
    
    // 시간 형식 변환 (초 -> "00:00:00")
    function formatTime(seconds) {
        if (seconds <= 0) return "00:00:00";
        
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = Math.floor(seconds % 60);
        
        var hh = h.toString().padStart(2, '0');
        var mm = m.toString().padStart(2, '0');
        var ss = s.toString().padStart(2, '0');
        
        return hh + ":" + mm + ":" + ss;
    }
    
    // 위치에서 프레임 계산
    function positionToFrame(position, fps) {
        if (position < 0 || fps <= 0) return 0;
        
        return Math.round(position * fps);
    }
    
    // 프레임에서 위치 계산
    function frameToPosition(frame, fps) {
        if (frame < 0 || fps <= 0) return 0.0;
        
        return frame / fps;
    }
} 