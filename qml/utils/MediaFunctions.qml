pragma Singleton
import QtQuick

// 미디어 파일 관련 유틸리티 함수들
QtObject {
    id: root
    
    // 경로에서 파일 이름만 추출
    function getFileName(path) {
        if (!path) return "";
        
        // 경로 구분자로 분리
        var parts = path.split('/');
        if (parts.length <= 1) {
            parts = path.split('\\');
        }
        
        return parts[parts.length - 1];
    }
    
    // 시간(초)을 타임코드로 변환 (00:00:00:00)
    function secondsToTimecode(seconds, fps) {
        if (seconds < 0 || isNaN(seconds)) return "00:00:00:00";
        
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        var secs = Math.floor(seconds % 60);
        var frames = Math.floor((seconds - Math.floor(seconds)) * (fps || 24));
        
        return String(hours).padStart(2, '0') + ":" +
               String(minutes).padStart(2, '0') + ":" +
               String(secs).padStart(2, '0') + ":" +
               String(frames).padStart(2, '0');
    }
    
    // 프레임을 타임코드로 변환
    function frameToTimecode(frame, fps) {
        if (frame < 0 || !fps || fps <= 0) return "00:00:00:00";
        
        var seconds = frame / fps;
        return secondsToTimecode(seconds, fps);
    }
    
    // 파일 크기 포맷팅 (MB, GB 등)
    function formatFileSize(bytes) {
        if (bytes < 1024) return bytes + " B";
        else if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        else if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB";
        else return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }
    
    // 파일 확장자 추출
    function getFileExtension(path) {
        if (!path) return "";
        
        var parts = path.split('.');
        if (parts.length <= 1) return "";
        
        return parts[parts.length - 1].toLowerCase();
    }
    
    // 미디어 파일 여부 확인
    function isMediaFile(path) {
        var ext = getFileExtension(path);
        var mediaExtensions = ["mp4", "mkv", "avi", "mov", "wmv", "webm", "m4v", "mpg", "mpeg", "flv", "3gp"];
        
        return mediaExtensions.indexOf(ext) >= 0;
    }
} 