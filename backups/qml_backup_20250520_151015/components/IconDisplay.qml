import QtQuick

// Icon component using text-based fallbacks to ensure visibility
Item {
    id: iconRoot
    
    property string iconName: ""
    property real size: 16
    property color iconColor: "white"
    property color hoverColor: "#0078D7" // Default accent color
    property bool isHovered: false
    property bool isPressed: false
    
    width: size
    height: size
    
    // Text fallback icon (always visible)
    Text {
        id: fallbackIcon
        anchors.centerIn: parent
        visible: true
        font.family: "Segoe UI Symbol"
        font.pixelSize: parent.size * 0.8
        text: {
            switch(parent.iconName) {
                case "play": return "▶"; 
                case "pause": return "⏸"; 
                case "stop": return "⏹"; 
                case "rewind": return "⏮"; 
                case "fast_forward": return "⏭"; 
                case "frame_backward": return "◀|"; 
                case "frame_forward": return "|▶"; 
                case "backward": return "◀"; 
                case "forward": return "▶"; 
                case "settings": return "⚙"; 
                case "folder": return "📂"; 
                case "fullscreen": return "⤢"; 
                case "fullscreen_exit": return "⤓"; 
                case "screenshot": return "📷"; 
                case "magnifier": return "🔍"; 
                default: return "?";
            }
        }
        color: parent.isPressed ? Qt.darker(parent.hoverColor, 1.2) :
               parent.isHovered ? parent.hoverColor : 
               parent.iconColor
    }
} 