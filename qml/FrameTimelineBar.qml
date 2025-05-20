import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "utils"

// Frame-accurate timeline for precise frame navigation
Item {
    id: root
    width: parent.width
    height: 40
    
    // Essential properties
    property var mpvObject: null // MPV player object
    property int currentFrame: 0
    property int totalFrames: 100
    property real fps: 24.0
    property bool isPlaying: false
    
    // Signal when user requests to seek to a specific frame
    signal seekRequested(int frame)
    
    // Frame visualization settings
    property int majorFrameInterval: 5  // Show bigger marker every N frames
    property int timecodeInterval: Math.max(10, Math.floor(fps))  // Show timecode every N frames
    
    // Use theme colors
    property color backgroundColor: ThemeManager.timelineBackgroundColor
    property color frameColor: ThemeManager.timelineFrameColor
    property color majorFrameColor: ThemeManager.timelineMajorFrameColor
    property color playheadColor: ThemeManager.timelinePlayheadColor
    property color activeTrackColor: ThemeManager.accentColor
    property color timecodeFontColor: ThemeManager.textColor
    property int timecodeFontSize: ThemeManager.smallFontSize
    property string timecodeFontFamily: ThemeManager.monoFont

    // Calculate timeline dimensions to always fill width
    property real frameSpacing: Math.max(2, width / Math.max(1, totalFrames))
    property real scaleFactor: width / Math.max(1, totalFrames)
    
    // Track state
    property bool isDragging: false
    property int dragFrame: 0  // Store the exact frame being dragged to
    property int lastSentFrame: -1  // Track the last frame we sent for seeking
    property bool throttleSeeking: true  // Throttle seeking while dragging for better performance
    
    // Direct playhead position tracking
    property real playheadPosition: getExactFramePosition(currentFrame)
    property bool seekInProgress: false  // Flag indicating seek operation in progress
    
    // Frame counter display calculation
    property int displayOffset: (mpvObject && mpvObject.oneBasedFrameNumbers) ? 1 : 0
    property string frameCounterText: {
        if (isDragging) {
            return (dragFrame + displayOffset) + " / " + (totalFrames ? (totalFrames + displayOffset - 1) : 0);
        } else {
            return (currentFrame + displayOffset) + " / " + (totalFrames ? (totalFrames + displayOffset - 1) : 0);
        }
    }
    
    // Snap playhead position to exact frame
    function getExactFramePosition(frame) {
        // Defensive code for invalid totalFrames
        if (totalFrames <= 0) return 0;
        
        // Safely limit frame range
        var safeFrame = Math.max(0, Math.min(frame, totalFrames - 5));
        return Math.round(safeFrame * scaleFactor - 1);
    }
    
    // Force playhead position update timer
    Timer {
        id: forceUpdateTimer
        interval: 33  // ~30fps (more stable value)
        repeat: true
        running: isPlaying || seekInProgress // Update playhead position when playing or seeking
        onTriggered: {
            // Force update playhead position to match current frame
            if (!isDragging) {
                // Only update when not dragging
                playheadPosition = getExactFramePosition(currentFrame);
                playhead.x = playheadPosition;
            }
        }
    }
    
    // Precise frame seek function - solves end-of-video issues
    function preciseFrameSeek(frame, exact) {
        // Ignore if MPV is not available or video has no duration
        if (!mpvObject || typeof mpvObject.duration === 'undefined' || mpvObject.duration <= 0) return;
        
        // Check frame range - handle safely
        var safeFrame = Math.max(0, Math.min(frame, totalFrames - 30));
        
        try {
            // Convert frame to time position
            var pos = safeFrame / fps;
        
            // Handle seeking near the end
            var isTooCloseToEnd = (totalFrames - safeFrame) < 30;
        
            // Update current frame immediately (UI responsiveness)
            currentFrame = safeFrame;
            
            // Set status variable - prevent duplicate seeks
            seekInProgress = true;
            
            // Reset endReached state when seeking
            if (mpvObject.endReached) {
                mpvObject.resetEndReached();
            }
        
            // Execute MPV command - use safe mode at end
            if (isTooCloseToEnd) {
                // Seek to a safer position when close to the end
                var safePos = Math.max(0, mpvObject.duration - 0.5);
                mpvObject.command(["seek", safePos, "absolute", "exact"]);
                
                // Always maintain paused state
                mpvObject.command(["set_property", "pause", "yes"]);
                
                // Perform quick verification
                verifySeekTimer.interval = 50;
                verifySeekTimer.restart();
            } else if (exact) {
                mpvObject.command(["seek", pos, "absolute", "exact"]);
                verifySeekTimer.interval = 80;
                verifySeekTimer.restart();
            } else {
                mpvObject.command(["seek", pos, "absolute", "exact"]);
                verifySeekTimer.interval = 60;
                verifySeekTimer.restart();
            }
            
            // Update playhead position immediately
            playheadPosition = getExactFramePosition(safeFrame);
            playhead.x = playheadPosition;
        } catch (e) {
            // console.error("Error during seek:", e);
            seekInProgress = false;
        }
    }
    
    // Post-seek verification timer - stronger synchronization
    Timer {
        id: verifySeekTimer
        interval: 80
        repeat: false
        onTriggered: {
            try {
                // 1. Check actual position after final seek
                if (mpvObject) {
                    var finalPos = mpvObject.getProperty("time-pos");
                    if (finalPos !== undefined && finalPos !== null) {
                        var finalFrame = Math.round(finalPos * fps);
                        // Synchronize again if calculated frame differs from current frame
                        if (finalFrame !== currentFrame && Math.abs(finalFrame - currentFrame) > 1) {
                            // Don't force adjust if at the end of timeline
                            if (currentFrame < totalFrames - 20) {
                                currentFrame = finalFrame;
                                playheadPosition = getExactFramePosition(finalFrame);
                                playhead.x = playheadPosition;
                            }
                        }
                    }
                }
            
                // 2. Complete seek process
                seekInProgress = false;
            } catch (e) {
                // console.error("Seek verification error:", e);
                seekInProgress = false;
            }
        }
    }
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        border.color: ThemeManager.borderColor
        border.width: 1
    }
    
    // Frame markers container
    Item {
        id: timelineContent
        anchors.fill: parent
        clip: true // Prevent drawing outside bounds
        
        // Draw all frame markers using Canvas for better performance
        Canvas {
            id: frameMarkers
            anchors.fill: parent
            
            // Use layer for hardware acceleration where available
            layer.enabled: true
            layer.samples: 2  // Reduced sampling (performance improvement)
            
            // Optimization for canvas rendering speed
            renderStrategy: Canvas.Cooperative 
            renderTarget: Canvas.FramebufferObject
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                
                var w = width;
                var h = height;
                var frameCount = totalFrames;
                
                // Avoid division by zero and handle empty timeline
                if (frameCount <= 0) {
                    return;
                }
                
                // Calculate thinning factor for high frame counts
                var thinningFactor = 1;
                if (frameCount > w) {
                    thinningFactor = Math.ceil(frameCount / w);
                }
                
                // Draw frame markers - optimized for large frame counts
                ctx.lineWidth = 1;
                
                // Draw standard markers
                ctx.strokeStyle = frameColor;
                
                // Loop optimized to avoid rendering too many markers
                for (var i = 0; i < frameCount; i += thinningFactor) {
                    var x = i * scaleFactor;
                    
                    // Skip markers that would be too close together
                    if (scaleFactor < 3 && i % 2 !== 0) continue;
                    
                    // Determine marker height based on type
                    var markerHeight = 8;  // Default height
                    
                    // Major frame markers
                    if (i % majorFrameInterval === 0) {
                        markerHeight = 12;
                        ctx.strokeStyle = majorFrameColor;
                    } else {
                        ctx.strokeStyle = frameColor;
                    }
                    
                    // Draw marker
                    ctx.beginPath();
                    ctx.moveTo(x, h - markerHeight);
                    ctx.lineTo(x, h);
                    ctx.stroke();
                }
            }
            
            // Update when timeline data changes
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
        
        // Timecode labels (only shown if there's enough space)
        Repeater {
            model: Math.ceil(totalFrames / timecodeInterval)
            
            // Timecode label
            Text {
                x: index * timecodeInterval * scaleFactor - width / 2
                y: 2
                visible: scaleFactor * timecodeInterval > 20 // Only show if enough space
                color: timecodeFontColor
                font.pixelSize: timecodeFontSize
                font.family: timecodeFontFamily
                text: formatTimecode(index * timecodeInterval)
            }
        }
        
        // Current playhead indicator
        Rectangle {
            id: playhead
            x: playheadPosition
            width: 2
            height: parent.height
            color: playheadColor
            
            // Playhead handle (larger area for clicking)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0
                width: 10
                height: 10
                radius: 5
                color: playheadColor
            }
        }
        
        // Dragging overlay (covers whole timeline)
        MouseArea {
            id: timelineDrag
            anchors.fill: parent
            hoverEnabled: true
            
            onPressed: function(mouse) {
                // Calculate the frame at click position
                var clickPos = mouse.x;
                var clickFrame = Math.floor(clickPos / scaleFactor);
                
                // Clamp to valid range
                clickFrame = Math.max(0, Math.min(clickFrame, totalFrames - 1));
                
                // Start dragging
                isDragging = true;
                dragFrame = clickFrame;
                
                // Move playhead
                playhead.x = getExactFramePosition(clickFrame);
                
                // Seek immediately on click
                if (mpvObject) {
                    preciseFrameSeek(clickFrame, true);
                    lastSentFrame = clickFrame;
                }
            }
            
            onPositionChanged: function(mouse) {
                if (isDragging) {
                    // Calculate the frame at drag position
                    var dragPos = Math.max(0, Math.min(mouse.x, width));
                    var newDragFrame = Math.floor(dragPos / scaleFactor);
                    
                    // Clamp to valid range
                    newDragFrame = Math.max(0, Math.min(newDragFrame, totalFrames - 1));
                    
                    // Update drag frame
                    if (dragFrame !== newDragFrame) {
                        dragFrame = newDragFrame;
                        
                        // Move playhead
                        playhead.x = getExactFramePosition(newDragFrame);
                        
                        // Throttle seeking while dragging
                        if (!throttleSeeking || 
                            lastSentFrame === -1 || 
                            Math.abs(newDragFrame - lastSentFrame) >= 5) {
                            
                            if (mpvObject) {
                                preciseFrameSeek(newDragFrame, false);
                                lastSentFrame = newDragFrame;
                            }
                        }
                    }
                }
            }
            
            onReleased: function() {
                if (isDragging) {
                    // End dragging
                    isDragging = false;
                    
                    // Final precise seek
                    if (mpvObject) {
                        preciseFrameSeek(dragFrame, true);
                    }
                    
                    // Notify about seek request
                    seekRequested(dragFrame);
                }
            }
        }
    }
    
    // Frame counter display
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.top: parent.top
        anchors.topMargin: 5
        height: 20
        width: frameCounterTextMetrics.width + 12
        color: Qt.rgba(0, 0, 0, 0.6)
        radius: 3
        
        // Text metrics for sizing
        TextMetrics {
            id: frameCounterTextMetrics
            font.family: timecodeFontFamily
            font.pixelSize: timecodeFontSize
            text: frameCounterText
        }
        
        // Counter text
        Text {
            anchors.centerIn: parent
            font.family: timecodeFontFamily
            font.pixelSize: timecodeFontSize
            color: timecodeFontColor
            text: frameCounterText
        }
    }
    
    // Format frame as timecode
    function formatTimecode(frame) {
        if (fps <= 0) return "00:00:00";
        
        var totalSeconds = frame / fps;
        var hours = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        var seconds = Math.floor(totalSeconds % 60);
        var frames = Math.floor((totalSeconds * fps) % fps);
        
        // Format as HH:MM:SS:FF
        return pad(hours) + ":" + pad(minutes) + ":" + pad(seconds) + ":" + pad(frames);
    }
    
    // Pad numbers to 2 digits
    function pad(num) {
        return num < 10 ? "0" + num : num;
    }
} 