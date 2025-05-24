import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../utils"
import "../ui"

// 플레이어 컨트롤 바 + 타임라인
Rectangle {
    id: root
    color: ThemeManager.controlBgColor
    height: 40 + ThemeManager.controlBarHeight  // 타임라인(40) + 컨트롤(ThemeManager에서 정의)
    
    // 프로퍼티
    property alias frameTimeline: timelineBar
    property bool isPlaying: false
    property int currentFrame: 0
    property int totalFrames: 0
    property real fps: 24.0
    
    // TimelineSync 객체 참조 (중앙 동기화 허브)
    property var timelineSync: null
    
    // 오버플로우 방지를 위한 안전한 currentFrame 처리 (수정됨)
    onCurrentFrameChanged: {
        // 극단적인 오버플로우만 즉시 보정 (5프레임 이상 초과)
        if (totalFrames > 0 && currentFrame >= totalFrames + 5) {
            console.warn("ControlBar: Extreme frame overflow detected - currentFrame:", currentFrame, "totalFrames:", totalFrames);
            // 안전한 범위로 제한 (최대값은 totalFrames - 1)
            currentFrame = totalFrames - 1;
        } else if (currentFrame < -5) {  // 극단적인 음수만 보정
            console.warn("ControlBar: Extreme negative frame detected:", currentFrame);
            currentFrame = 0;
        }
        // 경미한 오버플로우 (1-4프레임)는 자동 루프/재시작을 위해 허용
    }
    
    // totalFrames가 변경될 때도 currentFrame 범위 검증
    onTotalFramesChanged: {
        if (totalFrames > 0 && currentFrame >= totalFrames) {
            console.warn("ControlBar: Current frame out of range after totalFrames change:", currentFrame, "->", totalFrames - 1);
            currentFrame = totalFrames - 1;
        }
    }
    
    // 플레이 중 지속적인 프레임 오버플로우 방지 타이머 (수정됨)
    Timer {
        id: frameOverflowProtectionTimer
        interval: 500  // 간격을 늘려서 덜 공격적으로 작동
        repeat: true
        running: root.isPlaying  // 플레이 중일 때만 실행
        
        property int consecutiveOverflows: 0  // 연속 오버플로우 카운터
        property int maxConsecutiveOverflows: 3  // 3번 연속 오버플로우 시에만 중단
        
        onTriggered: {
            // 플레이 중 프레임 오버플로우 방지 (더 관대한 조건)
            if (root.totalFrames > 0 && root.currentFrame >= root.totalFrames) {
                consecutiveOverflows++;
                console.warn("ControlBar: Overflow detected (", consecutiveOverflows, "/", maxConsecutiveOverflows, ") - frame:", root.currentFrame, "total:", root.totalFrames);
                
                // 연속으로 여러 번 오버플로우가 발생한 경우에만 중단
                if (consecutiveOverflows >= maxConsecutiveOverflows) {
                    console.warn("ControlBar: Persistent overflow - safety stop at frame:", root.totalFrames - 1);
                    
                    // 안전한 마지막 프레임으로 설정
                    root.currentFrame = root.totalFrames - 1;
                    
                    // 재생 중단 (마지막 프레임에 도달)
                    if (root.isPlaying) {
                        console.log("ControlBar: Auto-pause due to persistent overflow");
                        playPauseRequested();  // 재생 중단 요청
                    }
                    
                    consecutiveOverflows = 0;  // 카운터 리셋
                }
            } else {
                // 정상 범위면 카운터 리셋
                if (consecutiveOverflows > 0) {
                    console.log("ControlBar: Frame back to normal range - resetting overflow counter");
                    consecutiveOverflows = 0;
                }
            }
        }
    }
    
    // Video metadata properties
    property string videoCodec: ""
    property string videoFormat: ""
    property string videoResolution: ""
    property string videoBitrate: ""
    
    // 비디오 파일 경로 (파일이 변경되었는지 확인하기 위해)
    property string videoPath: ""
    property string _lastVideoPath: ""
    
    // 비디오 파일 확장자 목록 - 필요한 확장자 추가
    readonly property var videoExtensions: [
        ".mp4", ".mov", ".avi", ".mkv", ".webm", ".wmv", ".flv", 
        ".mpg", ".mpeg", ".m4v", ".3gp", ".vob", ".mts", ".m2ts"
    ]
    
    // 캐싱된 메타데이터 값
    property string _cachedCodecDisplayText: "LOADING..."
    property string _cachedFpsDisplayText: "LOADING..."
    property bool _metadataInitialized: false
    
    // 중요: MPV 객체 참조 추가
    property var mpvObject: null
    
    // 시그널 연결 중복 방지를 위한 플래그
    property bool _signalsConnected: false
    
    // TimelineSync 연결 및 동기화
    onTimelineSyncChanged: {
        if (timelineSync) {
            console.log("ControlBar: TimelineSync connected");
            
            // TimelineSync에서 데이터 가져오기
            timelineSync.currentFrameChanged.connect(function(frame) {
                if (currentFrame !== frame) {
                    currentFrame = frame;
                }
            });
            
            timelineSync.totalFramesChanged.connect(function(frames) {
                if (totalFrames !== frames) {
                    totalFrames = frames;
                }
            });
            
            timelineSync.fpsChanged.connect(function(newFps) {
                if (fps !== newFps) {
                    fps = newFps;
                }
            });
            
            timelineSync.playingStateChanged.connect(function(playing) {
                if (isPlaying !== playing) {
                    isPlaying = playing;
                }
            });
        }
    }
    
    // MPV 객체가 변경될 때 메타데이터 초기화 및 이벤트 연결
    onMpvObjectChanged: {
        console.log("ControlBar: mpvObject changed:", mpvObject ? "valid" : "null");
        if (mpvObject && !_signalsConnected) {
            // MPV 객체 설정 시 강제로 메타데이터 초기화
            _metadataLoaded = false;
            _metadataInitialized = false;
            
            // 시그널 연결 시도 (한 번만)
            try {
                if (typeof mpvObject.videoMetadataChanged === "function" || 
                    mpvObject.hasOwnProperty('videoMetadataChanged')) {
                    mpvObject.videoMetadataChanged.connect(function() {
                        console.log("ControlBar: Received MPV metadata change signal");
                        if (!_metadataLoaded) {  // 아직 로딩되지 않은 경우만
                        refreshMetadata();
                        }
                    });
                    console.log("ControlBar: videoMetadataChanged signal connected");
                }
                
                // fileLoaded 시그널 연결 시도 (한 번만)
                if (typeof mpvObject.fileLoaded === "function" || 
                    mpvObject.hasOwnProperty('fileLoaded')) {
                    mpvObject.fileLoaded.connect(function() {
                        console.log("ControlBar: Received MPV file load completed signal");
                        
                        // 새 파일인 경우만 메타데이터 리셋
                        if (!_metadataLoaded) {
                            console.log("ControlBar: New file detected, refreshing metadata");
                        refreshMetadataForNewFile();
                        } else {
                            console.log("ControlBar: File already loaded, skipping metadata refresh");
                        }
                    });
                    console.log("ControlBar: fileLoaded signal connected");
                }
                
                _signalsConnected = true;  // 시그널 연결 완료 표시
                
            } catch (e) {
                console.error("ControlBar: Signal connection error:", e);
            }
            
            // 즉시 메타데이터 새로고침 (초기 로딩만)
            if (!_metadataLoaded) {
            refreshMetadataForNewFile();
            }
        }
    }
    
    // 메타데이터가 이미 로드되었는지 추적하는 플래그
    property bool _metadataLoaded: false
    
    // 파일 경로에서 경로와 확장자 분리
    function getFilePathAndExt(path) {
        if (!path) return { path: "", ext: "" };
        var lastDotIndex = path.lastIndexOf(".");
        if (lastDotIndex === -1) return { path: path, ext: "" };
        
        return { 
            path: path.substring(0, lastDotIndex), 
            ext: path.substring(lastDotIndex).toLowerCase()
        };
    }
    
    // 새 비디오 경로가 설정되면 메타데이터 새로고침
    onVideoPathChanged: {
        if (videoPath) {
            // 경로 분석
            var newFile = getFilePathAndExt(videoPath);
            var lastFile = getFilePathAndExt(_lastVideoPath);
            
            console.log("ControlBar: Path change detected -", videoPath);
            
            // 새 파일 로드로 간주하는 조건: 
            // 1. 경로나 확장자가 다른 경우
            // 2. 재로드인 경우(같은 경로지만 명시적으로 새로 로드한 경우)
            var isNewFile = (newFile.path !== lastFile.path || newFile.ext !== lastFile.ext);
            var isReload = (videoPath === _lastVideoPath && !_metadataLoaded);
            
            if (isNewFile || isReload) {
                console.log("ControlBar: New video file detected -", newFile.path, "extension:", newFile.ext, 
                            "reload:", isReload);
                
                // 즉시 로딩 표시
                _cachedCodecDisplayText = "LOADING...";
                _cachedFpsDisplayText = "LOADING...";
                
                // 메타데이터 초기화 상태 리셋 (새 파일만)
                _metadataInitialized = false;
                _metadataLoaded = false;
                
                // 메타데이터 갱신 (중복 방지 로직 포함)
                refreshMetadataForNewFile();
                
            } else {
                console.log("ControlBar: Same file path, skipping metadata refresh");
            }
        }
    }
    
    // 외부에서 호출할 수 있는 새 파일 메타데이터 새로고침 함수
    function refreshMetadataForNewFile() {
        // 강제 새로고침 여부 확인 (영상이 변경된 경우)
        var forceRefresh = videoPath !== _lastVideoPath;
        
        // 이미 로드된 경우 강제 새로고침이 아니면 스킵
        if (_metadataLoaded && !forceRefresh) {
            console.log("ControlBar: Metadata already loaded, skipping refresh");
            return;
        }
        
        // MPV 객체가 없으면 스킵
        if (!mpvObject) {
            console.log("ControlBar: No MPV object, cannot load metadata");
            return;
        }
        
        // 중복 호출 방지 - 이미 진행 중이면 스킵
        if (initMetadataTimer.running) {
            console.log("ControlBar: Metadata refresh already in progress, skipping");
            return;
        }
        
        console.log("ControlBar: Initializing metadata for new file", forceRefresh ? "(forced refresh)" : "");
        
        // 새 파일인 경우만 메타데이터 상태 초기화
        if (forceRefresh) {
        _metadataLoaded = false;
        _metadataInitialized = false;
            _lastVideoPath = videoPath;  // 경로 업데이트
        }
        
        // 메타데이터 즉시 갱신 시도 (중복 방지)
        if (!_metadataLoaded) {
        refreshMetadata();
        }
        
        // 메타데이터 초기화 타이머 시작 (백업 메커니즘, 한 번만)
        if (!initMetadataTimer.running) {
            initMetadataTimer.start();
        }
    }
    
    // 이전 MPV 객체 변경 핸들러 - 상단에 통합되었습니다
    // 참고: onMpvObjectChanged는 이미 위에 정의되어 있습니다
    
    // 메타데이터 초기화 타이머 (한 번만 실행)
    Timer {
        id: initMetadataTimer
        interval: 500 // 500ms 딜레이 - 비디오 로드 후 메타데이터가 준비되도록
        repeat: false
        onTriggered: {
            console.log("ControlBar: Metadata timer triggered");
            if (!_metadataLoaded && !_metadataRefreshInProgress) {
            refreshMetadata();
            } else {
                console.log("ControlBar: Skipping timer refresh - already loaded or in progress");
            }
        }
    }
    
    // 메타데이터 새로고침 함수 (직접 호출할 수 있도록)
    property bool _metadataRefreshInProgress: false  // 메타데이터 새로고침 진행 중 플래그
    
    function refreshMetadata() {
        if (!mpvObject) {
            console.error("ControlBar: Failed to refresh metadata - no MPV object");
            return;
        }
        
        // 이미 진행 중이면 스킵
        if (_metadataRefreshInProgress) {
            console.log("ControlBar: Metadata refresh already in progress, skipping");
            return;
        }
        
        // 중복 로드 방지 (강제 새로고침 모드 아닐 경우)
        var forceRefresh = !_metadataInitialized || videoPath !== _lastVideoPath;
        if (_metadataLoaded && !forceRefresh) {
            console.log("ControlBar: Metadata already loaded, preventing duplicate loading");
            return;
        }
        
        _metadataRefreshInProgress = true;  // 진행 중 플래그 설정
        console.log("ControlBar: Starting metadata refresh", forceRefresh ? "(forced mode)" : "");
        
        try {
            // 디버깅: MPV 객체 속성 확인
            console.log("ControlBar: MPV object videoCodec =", mpvObject.videoCodec);
            console.log("ControlBar: MPV object videoFormat =", mpvObject.videoFormat);
            console.log("ControlBar: MPV object videoResolution =", mpvObject.videoResolution);
            
            // 코덱 정보 가져오기
            var codecInfo = [];
            
            // 코덱 추가 (여러 방법 시도)
            if (mpvObject.videoCodec && mpvObject.videoCodec.length > 0) {
                codecInfo.push(mpvObject.videoCodec.toUpperCase());
                console.log("ControlBar: Codec info retrieved from direct property:", mpvObject.videoCodec);
            } else {
                try {
                    // getProperty 방식으로 시도
                    var codec = mpvObject.getProperty("video-codec");
                    if (codec) {
                        codecInfo.push(codec.toString().toUpperCase());
                        console.log("ControlBar: Codec info retrieved from getProperty:", codec);
                    } else {
                        // 다른 방법으로 시도 (track-list)
                        var tracks = mpvObject.getProperty("track-list");
                        if (tracks && Array.isArray(tracks)) {
                            for (var i = 0; i < tracks.length; i++) {
                                if (tracks[i].type === "video" && tracks[i].selected && tracks[i].codec) {
                                    codecInfo.push(tracks[i].codec.toUpperCase());
                                    console.log("ControlBar: Codec info retrieved from track-list:", tracks[i].codec);
                                    break;
                                }
                            }
                        }
                    }
                } catch (e) {
                    console.error("ControlBar: Failed to get codec info:", e);
                }
            }
            
            // 포맷 추가 (여러 방법 시도)
            if (mpvObject.videoFormat && mpvObject.videoFormat.length > 0) {
                codecInfo.push(mpvObject.videoFormat.toUpperCase());
                console.log("ControlBar: Video format retrieved from direct property:", mpvObject.videoFormat);
            } else {
                try {
                    // 여러 속성 시도
                    var format = mpvObject.getProperty("video-format") || 
                                 mpvObject.getProperty("video-params/pixelformat") ||
                                 mpvObject.getProperty("video-params/hw-pixelformat");
                    
                    if (format) {
                        codecInfo.push(format.toString().toUpperCase());
                        console.log("ControlBar: Video format retrieved from getProperty:", format);
                    }
                } catch (e) {
                    console.error("ControlBar: Failed to get format info:", e);
                }
            }
            
            // 해상도 추가 (여러 방법 시도)
            if (mpvObject.videoResolution && mpvObject.videoResolution.length > 0) {
                codecInfo.push(mpvObject.videoResolution);
                console.log("ControlBar: Resolution retrieved from direct property:", mpvObject.videoResolution);
            } else {
                try {
                    var width = mpvObject.getProperty("width") || mpvObject.getProperty("video-params/w");
                    var height = mpvObject.getProperty("height") || mpvObject.getProperty("video-params/h");
                    
                    if (width && height) {
                        var resolution = width + "×" + height;
                        codecInfo.push(resolution);
                        console.log("ControlBar: Resolution retrieved from getProperty:", resolution);
                    }
                } catch (e) {
                    console.error("ControlBar: Failed to get resolution info:", e);
                }
            }
            
            // 캐시 업데이트
            if (codecInfo.length > 0) {
                _cachedCodecDisplayText = codecInfo.join(" ");
                console.log("ControlBar: Codec info cached:", _cachedCodecDisplayText);
            } else {
                // 메타데이터를 가져오지 못한 경우
                _cachedCodecDisplayText = "NO INFO";
                console.warn("ControlBar: Could not retrieve codec info");
            }
            
            // FPS 정보 가져오기 (여러 방법 시도)
            var mpvFps = 0;
            if (fps > 0) {
                mpvFps = fps;
                console.log("ControlBar: FPS retrieved from parent property:", fps);
            } else if (mpvObject.fps > 0) {
                mpvFps = mpvObject.fps;
                console.log("ControlBar: FPS retrieved from direct property:", mpvObject.fps);
            } else {
                try {
                    // 여러 속성 시도
                    mpvFps = mpvObject.getProperty("fps") || 
                             mpvObject.getProperty("container-fps") || 
                             mpvObject.getProperty("estimated-vf-fps");
                    
                    if (mpvFps && mpvFps > 0) {
                        console.log("ControlBar: FPS retrieved from getProperty:", mpvFps);
                    } else {
                        mpvFps = 23.976; // 기본값
                        console.warn("ControlBar: Could not get FPS info, using default value");
                    }
                } catch (e) {
                    console.error("ControlBar: Failed to get FPS info:", e);
                    mpvFps = 23.976;
                }
            }
            
            // FPS 표시 텍스트 업데이트
            if (mpvFps > 0) {
                _cachedFpsDisplayText = mpvFps.toFixed(3) + "F";
                console.log("ControlBar: FPS info cached:", _cachedFpsDisplayText);
            } else {
                _cachedFpsDisplayText = "23.976F";
                console.warn("ControlBar: No valid FPS info, using default value");
            }
            
            _metadataInitialized = true;
            _metadataLoaded = true; // 메타데이터 로드 완료 표시
            
            // 디버깅: 최종 표시 텍스트 확인
            console.log("ControlBar: Final metadata display - Codec:", _cachedCodecDisplayText, "FPS:", _cachedFpsDisplayText);
            
        } catch (e) {
            console.error("ControlBar: Metadata initialization error:", e);
            _cachedCodecDisplayText = "ERROR";
            _cachedFpsDisplayText = "ERROR";
            _metadataInitialized = true;
            _metadataLoaded = true; // 오류가 발생해도 로드 시도는 완료된 것으로 처리
        } finally {
            _metadataRefreshInProgress = false;  // 진행 중 플래그 리셋 (성공/실패 관계없이)
        }
    }
    
    // Format codec display text - 캐싱된 값 사용
    property string codecDisplayText: _cachedCodecDisplayText
    
    // Format FPS display - 캐싱된 값 사용
    property string fpsDisplayText: _cachedFpsDisplayText
    
    // 시그널
    signal openFileRequested()
    signal playPauseRequested()
    signal frameBackRequested(int frames)
    signal frameForwardRequested(int frames)
    signal seekToFrameRequested(int frame)
    signal fullscreenToggleRequested()
    signal settingsToggleRequested()
    signal toggleScopesRequested()
    
    // 안전한 프레임 이동 함수들
    function safeFrameBack(frames) {
        var newFrame = Math.max(0, root.currentFrame - frames);
        console.log("ControlBar: Safe frame back:", root.currentFrame, "->", newFrame);
        seekToFrameRequested(newFrame);
    }
    
    function safeFrameForward(frames) {
        var maxFrame = root.totalFrames > 0 ? root.totalFrames - 1 : 0;
        var newFrame = Math.min(maxFrame, root.currentFrame + frames);
        console.log("ControlBar: Safe frame forward:", root.currentFrame, "->", newFrame);
        seekToFrameRequested(newFrame);
    }
    
    // 타임라인 영역
    Item {
        id: timelineArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 40
        
        // 타임라인 바
        FrameTimelineBar {
            id: timelineBar
            anchors.fill: parent
            
            // FrameTimelineBar에 currentFrame, totalFrames, fps 바인딩
            currentFrame: root.currentFrame
            totalFrames: root.totalFrames
            fps: root.fps
            isPlaying: root.isPlaying
            
            // 중요: MPV 객체 전달 - 반드시 null이 아닌지 검증
            mpvObject: root.mpvObject
            
            // TimelineSync 객체 전달 (중앙 동기화 허브)
            timelineSync: root.timelineSync
            
            // currentFrame 변경 감지 - 타임라인 내부 변경이 외부로 전달되도록
            onCurrentFrameChanged: {
                // 내부-외부 값이 다를 때만 업데이트 (무한 루프 방지)
                if (root.currentFrame !== currentFrame) {
                    root.currentFrame = currentFrame;
                }
            }
            
            // seekRequested 시그널을 상위로 올림 - 관대한 오버플로우 방지
            onSeekRequested: function(frame) {
                console.log("ControlBar: Frame seek request -", frame);
                
                // 관대한 프레임 범위 검증 (극단적인 경우만 보정)
                var safeFrame = frame;
                if (root.totalFrames > 0) {
                    // 극단적인 오버플로우만 보정 (10프레임 이상 초과)
                    if (frame >= root.totalFrames + 10) {
                        console.warn("ControlBar: Extreme seek overflow -", frame, "->", root.totalFrames - 1);
                        safeFrame = root.totalFrames - 1;
                    } else if (frame < -10) {  // 극단적인 음수만 보정
                        console.warn("ControlBar: Extreme seek underflow -", frame, "-> 0");
                        safeFrame = 0;
                    }
                    // 경미한 오버플로우는 MPV가 자체적으로 처리하도록 허용
                }
                
                // 내부 currentFrame도 함께 업데이트 (동기화 보장)
                if (root.currentFrame !== safeFrame) {
                    root.currentFrame = safeFrame;
                }
                
                // 상위 컴포넌트로 프레임 시그널 전달 (원본값 전달로 변경)
                root.seekToFrameRequested(frame);  // safeFrame이 아닌 원본 frame 전달
            }
        }
    }
    
    // 경계선
    Rectangle {
        anchors.top: timelineArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: ThemeManager.borderColor
    }
    
    // 컨트롤 버튼 영역 - 새로운 디자인
    Rectangle {
        id: controlsArea
        anchors.top: timelineArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: ThemeManager.controlBgColor
        
        // 왼쪽 프레임 정보 표시 영역
        Rectangle {
            id: frameInfoBox
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            width: frameRateText.width + 20
            height: 32
            radius: 4
            color: "#222222"
            
            Text {
                id: frameRateText
                anchors.centerIn: parent
                text: fpsDisplayText
                font.family: "Consolas"
                font.pixelSize: 14
                color: "white"
            }
        }
        
        // 중앙 컨트롤 버튼
        Item {
            anchors.centerIn: parent
            width: 250
            height: 60
            
            // 이미지 버튼 그룹
            Row {
                anchors.centerIn: parent
                spacing: 20
                
                // 처음으로 건너뛰기
                IconButton {
                    iconSource: "backward"
                    iconSize: 18
                    width: 36
                    height: 36
                    onClicked: {
                        if (root.mpvObject) {
                            console.log("ControlBar: Jump to start (safe frame: 0)");
                            seekToFrameRequested(0);
                        }
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Jump to Start"
                }
                
                // 프레임 뒤로 가기
                IconButton {
                    iconSource: "prev"
                    iconSize: 18
                    width: 36
                    height: 36
                    onClicked: safeFrameBack(1)
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Previous Frame"
                }
                
                // 재생/일시정지
                IconButton {
                    iconSource: isPlaying ? "pause" : "play"
                    iconSize: 24
                    width: 44
                    height: 44
                    
                    // 배경 있는 버튼
                    bgColorNormal: "#404040"
                    textColorNormal: "white"
                    
                    onClicked: playPauseRequested()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: isPlaying ? "Pause" : "Play"
                }
                
                // 프레임 앞으로 가기
                IconButton {
                    iconSource: "next"
                    iconSize: 18
                    width: 36
                    height: 36
                    onClicked: safeFrameForward(1)
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Next Frame"
                }
                
                // 마지막으로 건너뛰기
                IconButton {
                    iconSource: "forward"
                    iconSize: 18
                    width: 36
                    height: 36
                    onClicked: {
                        if (root.mpvObject && root.totalFrames > 0) {
                            var safeEndFrame = Math.max(0, root.totalFrames - 1);
                            console.log("ControlBar: Jump to end (safe frame:", safeEndFrame, ")");
                            seekToFrameRequested(safeEndFrame);
                        }
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Jump to End"
                }
            }
        }
        
        // 오른쪽 버튼 영역
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 20
            spacing: 10
            
            // SET 버튼 - 캡슐 형태로 변경, ThemeManager 속성 사용
            Rectangle {
                id: setButton
                width: 50
                height: ThemeManager.controlButtonHeight
                radius: ThemeManager.controlButtonRadius
                color: ThemeManager.controlButtonColor
                
                // 호버 애니메이션
                Behavior on color {
                    ColorAnimation { duration: ThemeManager.hoverAnimationDuration }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "SET"
                    font.pixelSize: 13
                    color: ThemeManager.controlButtonTextColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: settingsToggleRequested()
                    
                    // 호버 효과
                    hoverEnabled: true
                    onEntered: parent.color = ThemeManager.controlButtonHoverColor
                    onExited: parent.color = ThemeManager.controlButtonColor
                    onPressed: parent.color = ThemeManager.controlButtonPressedColor
                    onReleased: parent.color = hovered ? ThemeManager.controlButtonHoverColor : ThemeManager.controlButtonColor
                }
            }
            
            // OPEN 버튼 - 캡슐 형태로 변경, ThemeManager 속성 사용
            Rectangle {
                id: openButton
                width: 65
                height: ThemeManager.controlButtonHeight
                radius: ThemeManager.controlButtonRadius
                color: ThemeManager.controlButtonColor
                
                // 호버 애니메이션
                Behavior on color {
                    ColorAnimation { duration: ThemeManager.hoverAnimationDuration }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "OPEN"
                    font.pixelSize: 13
                    color: ThemeManager.controlButtonTextColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: openFileRequested()
                    
                    // 호버 효과
                    hoverEnabled: true
                    onEntered: parent.color = ThemeManager.controlButtonHoverColor
                    onExited: parent.color = ThemeManager.controlButtonColor
                    onPressed: parent.color = ThemeManager.controlButtonPressedColor
                    onReleased: parent.color = hovered ? ThemeManager.controlButtonHoverColor : ThemeManager.controlButtonColor
                }
            }
        }
        
        // 코덱 정보 표시
        Text {
            anchors.left: frameInfoBox.right
            anchors.verticalCenter: frameInfoBox.verticalCenter
            anchors.leftMargin: 10
            text: codecDisplayText
            color: ThemeManager.secondaryTextColor
            font.pixelSize: 12
            font.family: "Consolas"
        }
    }
    
    // 파일이 변경될 때 메타데이터를 새로고침하기 위한 연결
    // VideoPlayer 컴포넌트에서 비디오 파일이 로드되면 다음과 같이 설정:
    // controlBar.videoPath = "/path/to/video.mp4"
}