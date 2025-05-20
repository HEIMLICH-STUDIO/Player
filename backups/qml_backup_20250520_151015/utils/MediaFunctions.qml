pragma Singleton
import QtQuick

QtObject {
    // Frame info update function - optimized for better synchronization
    function updateFrameInfo(mpvObject, fps, totalFramesRef, currentFrameRef, currentTimecodeRef) {
        try {
            // 미디어가 로드되지 않았거나 준비되지 않은 경우 처리하지 않음
            if (!mpvObject || !mpvObject.filename || mpvObject.filename === "") {
                return null;
            }
            
            // mpv 속성 접근 전 안전성 확인
            try {
                var duration = mpvObject.duration;
                if (typeof duration === 'undefined' || duration <= 0) {
                    return null;
                }
            } catch (e) {
                console.error("Duration check error:", e);
                return null;
            }
            
            // FPS 초기화 - 한 번만 실행
            let currentFps = fps;
            if (!currentFps || currentFps <= 0) {
                try {
                    var estimatedFps = mpvObject.getProperty("estimated-vf-fps");
                    // FPS 값이 유효하지 않으면 기본값 사용
                    if (estimatedFps !== undefined && estimatedFps > 0) {
                        currentFps = parseFloat(estimatedFps.toFixed(3)); // 소수점 3자리로 정확히 고정
                    } else {
                        currentFps = 24.0; // 기본값 설정
                    }
                    console.log("FPS initialized to:", currentFps);
                } catch (e) {
                    console.error("FPS check error:", e);
                    currentFps = 24.0; // 기본값 설정
                }
            }
            
            // 안정적인 총 프레임 수 계산 (한 번만 계산하고 고정)
            let currentTotalFrames = totalFramesRef;
            if (currentTotalFrames <= 1 || Math.abs(currentTotalFrames - Math.ceil(mpvObject.duration * currentFps)) > currentFps) {
                // 큰 차이가 있을 때만 업데이트 (안정성)
                currentTotalFrames = Math.max(10, Math.ceil(mpvObject.duration * currentFps));
                console.log("Total frames calculated:", currentTotalFrames);
            }
            
            // 안전하게 포지션 정보 가져오기 (중요)
            var pos = 0;
            try {
                var directPos = mpvObject.getProperty("time-pos");
                
                // 더 안정적인 위치 계산 - mpvObject.lastPosition도 고려
                if (directPos !== undefined && directPos !== null && directPos >= 0) {
                    pos = directPos;
                } else if (typeof mpvObject.position !== 'undefined' && mpvObject.position >= 0) {
                    pos = mpvObject.position;
                } else if (typeof mpvObject.lastPosition !== 'undefined' && mpvObject.lastPosition >= 0) {
                    pos = mpvObject.lastPosition;
                }
            } catch (e) {
                console.error("Position check error:", e);
                if (typeof mpvObject.lastPosition !== 'undefined') {
                    pos = mpvObject.lastPosition;
                } else {
                    pos = 0;
                }
            }
            
            // 끝에 도달했을 때 안전하게 처리 - 더 큰 여유 확보
            if (pos >= mpvObject.duration - 0.2) {
                pos = Math.max(0, mpvObject.duration - 0.5);
                
                // 끝에 도달했을 때 자동으로 일시 정지
                if (!mpvObject.pause) {
                    mpvObject.command(["set_property", "pause", "yes"]);
                }
            }
            
            // 정확한 프레임 계산을 위한 수식 개선
            var newFrame = Math.min(currentTotalFrames - 1, Math.max(0, Math.round(pos * currentFps)));
            
            // 타임코드 포맷팅
            var hours = Math.floor(pos / 3600);
            var minutes = Math.floor((pos % 3600) / 60);
            var seconds = Math.floor(pos % 60);
            var frames = Math.floor((pos * currentFps) % currentFps);
            
            var newTimecode = 
                hours.toString().padStart(2, '0') + ":" +
                minutes.toString().padStart(2, '0') + ":" +
                seconds.toString().padStart(2, '0') + ":" +
                frames.toString().padStart(2, '0');
            
            return {
                fps: currentFps,
                totalFrames: currentTotalFrames,
                currentFrame: newFrame,
                currentTimecode: newTimecode
            };
            
        } catch (e) {
            console.error("Frame info update general error:", e);
            return null;
        }
    }
    
    // Frame navigation functions
    function goBackFrames(mpvObject, fps, numFrames) {
        try {
            if (!mpvObject) return false;
            
            var pos = mpvObject.position;
            var newPos = Math.max(0, pos - (numFrames / fps));
            
            mpvObject.setProperty("pause", true); // Ensure paused during frame stepping
            
            // 모든 경우에 단순한 시크 사용 - 더 안정적인 동작
            mpvObject.command(["seek", newPos - pos, "relative", "keyframes"]);
            
            return true;
        } catch (e) {
            console.error("Frame back error:", e);
            return false;
        }
    }
    
    function goForwardFrames(mpvObject, fps, numFrames) {
        try {
            if (!mpvObject) return false;
            
            var pos = mpvObject.position;
            var duration = mpvObject.duration || 0;
            
            // 끝에 도달하기 전에 더 큰 여유를 두어 안정성 향상
            var newPos = Math.min(duration - 0.5, pos + (numFrames / fps)); 
            
            mpvObject.setProperty("pause", true); // Ensure paused during frame stepping
            
            // 끝 부분에 가까워지면 안전 시크 사용
            var isTooCloseToEnd = (duration - newPos) < 0.5;
            if (isTooCloseToEnd) {
                // 끝 부분에서는 안전 모드 (끝에서 약간 떨어진 위치로)
                mpvObject.command(["seek", Math.max(0, duration - 0.5), "absolute", "keyframes"]);
            } else {
                // 일반적인 시크
                mpvObject.command(["seek", newPos - pos, "relative", "keyframes"]);
            }
            
            return true;
        } catch (e) {
            console.error("Frame forward error:", e);
            return false;
        }
    }
    
    // Media playback functions
    function playMedia(mpvObject, filePath, currentMediaFileRef) {
        if (!mpvObject) return false;
        
        console.log("Playing media:", filePath);
        
        // Normalize file path (remove file:///)
        let normalizedPath = filePath.toString();
        if (normalizedPath.startsWith("file:///")) {
            normalizedPath = normalizedPath.slice(8); // For Windows file:///C:/ -> C:/
        }
        
        try {
            mpvObject.command(["loadfile", normalizedPath]);
            return normalizedPath;  // Return the normalized path
        } catch (e) {
            console.error("Error loading file:", e);
            return false;
        }
    }
    
    // Helper function to convert seconds to display string
    function timeToDisplayString(seconds) {
        let hours = Math.floor(seconds / 3600);
        let minutes = Math.floor((seconds % 3600) / 60);
        seconds = Math.floor(seconds % 60);
        
        return hours.toString().padStart(2, '0') + ":" +
               minutes.toString().padStart(2, '0') + ":" +
               seconds.toString().padStart(2, '0');
    }
} 