import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import "../utils"

// File open/save dialog wrapper
// Uses Qt.labs.platform or QtQuick.Dialogs
// QtQuick.Dialogs recommended for Qt 6.4 and above
QtObject {
    id: root
    
    // Properties
    property string title: "Select File"
    property string folder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
    property var nameFilters: ["Video files (*.mp4 *.mkv *.avi *.mov *.wmv)", "All files (*.*)"]
    property bool selectMultiple: false
    property bool selectFolder: false
    property bool selectExisting: true // true=open, false=save
    
    // Signals
    signal fileSelected(string fileUrl)
    signal filesSelected(var fileUrls)
    signal accepted()
    signal rejected()
    
    // Internal implementation - Qt 6.x native dialog
    property var dialog: FileDialog {
        title: root.title
        currentFolder: root.folder ? StandardPaths.findFolder(root.folder) : StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: root.nameFilters
        fileMode: {
            if (root.selectFolder) return FileDialog.OpenDirectory
            if (root.selectMultiple) return FileDialog.OpenFiles
            return root.selectExisting ? FileDialog.OpenFile : FileDialog.SaveFile
        }
        
        onAccepted: {
            var selectedFile = selectedFile.toString();
            // Remove file:/// prefix from selected file path if needed
            selectedFile = selectedFile.replace(/^(file:\/{2})/, "");
            console.log("File selected:", selectedFile);
            
            // Emit file load signal when file is selected
            fileSelected(selectedFile);
        }
        
        onRejected: {
            console.log("File selection cancelled");
        }
    }
    
    // Open dialog
    function open() {
        try {
            dialog.open()
        } catch (e) {
            console.error("Error opening dialog:", e)
        }
    }
    
    // Close dialog
    function close() {
        try {
            dialog.close()
        } catch (e) {
            console.error("Error closing dialog:", e)
        }
    }
} 