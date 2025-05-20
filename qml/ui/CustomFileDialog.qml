import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import "../utils"

// 파일 열기/저장 다이얼로그 랩퍼
// Qt.labs.platform 또는 QtQuick.Dialogs 사용
// Qt 6.4 이상에서는 QtQuick.Dialogs 권장
QtObject {
    id: root
    
    // 속성
    property string title: "파일 선택"
    property string folder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
    property var nameFilters: ["비디오 파일 (*.mp4 *.mkv *.avi *.mov *.wmv)", "모든 파일 (*.*)"]
    property bool selectMultiple: false
    property bool selectFolder: false
    property bool selectExisting: true // true=열기, false=저장
    
    // 시그널
    signal fileSelected(string fileUrl)
    signal filesSelected(var fileUrls)
    signal accepted()
    signal rejected()
    
    // 내부 구현 - Qt 6.x 네이티브 다이얼로그
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
            console.log("파일 선택됨:", selectedFile)
            if (root.selectMultiple) {
                root.filesSelected(files)
            } else {
                root.fileSelected(selectedFile)
            }
            root.accepted()
        }
        
        onRejected: {
            console.log("파일 선택 취소됨")
            root.rejected()
        }
    }
    
    // 다이얼로그 열기
    function open() {
        try {
            dialog.open()
        } catch (e) {
            console.error("다이얼로그 열기 오류:", e)
        }
    }
    
    // 다이얼로그 닫기
    function close() {
        try {
            dialog.close()
        } catch (e) {
            console.error("다이얼로그 닫기 오류:", e)
        }
    }
} 