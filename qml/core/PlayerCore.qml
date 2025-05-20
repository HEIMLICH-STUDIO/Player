pragma Singleton
import QtQuick
import "../utils"

// 전역 플레이어 상태 및 기능 관리
QtObject {
    id: playerCore
    
    // 앱/플레이어 상태
    property bool ready: false
    property string version: "1.0.0"
    property var apiVersion: { "major": 1, "minor": 0 }
    
    // 셋팅
    property var settings: ({
        // 재생 설정
        autoPlay: false,
        loopPlayback: false,
        rememberPosition: true,
        
        // 비디오 설정
        hwAccel: "auto-copy",
        deinterlace: "auto",
        
        // 인터페이스 설정
        theme: "dark",
        showStatusInfo: true,
        showTimecodes: true,
        oneBasedFrames: false,
        
        // 파일 히스토리
        recentFiles: [],
        maxRecentFiles: 10
    })
    
    // 현재 재생 정보
    property var playback: ({
        currentFile: "",
        position: 0.0,
        duration: 0.0,
        fps: 24.0,
        currentFrame: 0,
        totalFrames: 0,
        volume: 100,
        muted: false,
        playing: false,
        speed: 1.0
    })
    
    // 초기화
    Component.onCompleted: {
        console.log("PlayerCore initialized");
        loadSettings();
        ready = true;
    }
    
    // 설정 로드
    function loadSettings() {
        var storedSettings = localStorage.getItem("settings");
        if (storedSettings) {
            try {
                var parsed = JSON.parse(storedSettings);
                // 기존 설정과 병합
                settings = Object.assign({}, settings, parsed);
            } catch (e) {
                console.error("설정 로드 실패:", e);
            }
        }
    }
    
    // 설정 저장
    function saveSettings() {
        try {
            localStorage.setItem("settings", JSON.stringify(settings));
        } catch (e) {
            console.error("설정 저장 실패:", e);
        }
    }
    
    // 최근 파일 추가
    function addRecentFile(path) {
        if (!path) return;
        
        // 중복 제거
        var index = settings.recentFiles.indexOf(path);
        if (index >= 0) {
            settings.recentFiles.splice(index, 1);
        }
        
        // 최근 파일 목록 앞에 추가
        settings.recentFiles.unshift(path);
        
        // 최대 개수 유지
        if (settings.recentFiles.length > settings.maxRecentFiles) {
            settings.recentFiles.length = settings.maxRecentFiles;
        }
        
        // 설정 저장
        saveSettings();
    }
    
    // 재생 정보 업데이트
    function updatePlaybackInfo(info) {
        playback = Object.assign({}, playback, info);
    }
    
    // 설정 값 변경
    function setSetting(key, value) {
        if (typeof settings[key] !== "undefined") {
            settings[key] = value;
            saveSettings();
        }
    }
} 