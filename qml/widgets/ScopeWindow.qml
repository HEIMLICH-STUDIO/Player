import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../utils"

Window {
    id: root
    title: qsTr("Scopes")
    width: 640
    height: 360
    color: ThemeManager.dialogColor
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
    visible: false

    // 메인 비디오 플레이어 참조
    property var videoArea: null
    property string currentFile: ""
    
    // 메인 비디오 파일이 변경될 때마다 스코프도 업데이트
    onVideoAreaChanged: {
        if (videoArea) {
            // 비디오 파일명 변경 감지
            videoArea.onOnFileChangedEvent.connect(function(filename) {
                if (filename !== "") {
                    currentFile = filename;
                    updateScopes();
                }
            });
        }
    }
    
    onVisibleChanged: {
        if (visible && currentFile !== "") {
            updateScopes();
        }
    }

    // 레이아웃
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // 스코프 컨트롤 영역
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: ThemeManager.tabBarColor
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15

                CheckBox {
                    id: histogramCheck
                    text: qsTr("히스토그램")
                    checked: true
                    
                    contentItem: Text {
                        text: parent.text
                        color: ThemeManager.textColor
                        font.pixelSize: 14
                        leftPadding: histogramCheck.indicator.width + 6
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onCheckedChanged: {
                        // 히스토그램 뷰 표시/숨김
                        if (scopeLoader.item && scopeLoader.item.histogramView) {
                            scopeLoader.item.histogramView.visible = histogramCheck.checked;
                            updateScopes();
                        }
                    }
                }

                CheckBox {
                    id: vectorscopeCheck
                    text: qsTr("벡터스코프")
                    checked: true
                    
                    contentItem: Text {
                        text: parent.text
                        color: ThemeManager.textColor
                        font.pixelSize: 14
                        leftPadding: vectorscopeCheck.indicator.width + 6
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onCheckedChanged: {
                        // 벡터스코프 뷰 표시/숨김
                        if (scopeLoader.item && scopeLoader.item.vectorscopeView) {
                            scopeLoader.item.vectorscopeView.visible = vectorscopeCheck.checked;
                            updateScopes();
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // 상태 텍스트
                Text {
                    id: statusText
                    color: ThemeManager.textColor
                    font.pixelSize: 12
                    text: "비디오를 먼저 로드하세요"
                    visible: currentFile === ""
                }
            }
        }
        
        // 구분선
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: ThemeManager.borderColor
        }
        
        // 스코프 영역
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#121212"
            
            // MPV 스코프 로더
            Loader {
                id: scopeLoader
                anchors.fill: parent
                active: true
                
                sourceComponent: Item {
                    id: scopeContainer
                    
                    // 히스토그램 및 벡터스코프 뷰를 외부에서 접근할 수 있도록 속성 추가
                    property alias histogramView: histogramView
                    property alias vectorscopeView: vectorscopeView
                    property alias histogramMpvLoader: histogramMpvLoader
                    property alias vectorscopeMpvLoader: vectorscopeMpvLoader
                    
                    // 히스토그램 뷰
                    Rectangle {
                        id: histogramView
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: parent.width / 2
                        height: parent.height
                        color: "#121212"
                        visible: histogramCheck.checked
                        
                        // 히스토그램 MPV 인스턴스
                        Loader {
                            id: histogramMpvLoader
                            anchors.fill: parent
                            anchors.margins: 10
                            active: typeof hasMpvSupport !== "undefined" ? hasMpvSupport : false
                            
                            sourceComponent: Component {
                                Item {
                                    property var mpvPlayer: null
                                    
                                    Component.onCompleted: {
                                        try {
                                            // MPV 인스턴스 생성
                                            var component = Qt.createQmlObject(
                                                'import mpv 1.0; MpvObject { anchors.fill: parent }',
                                                this,
                                                "histogram_mpv"
                                            );
                                            
                                            if (component) {
                                                mpvPlayer = component;
                                                console.log("Histogram MPV created");
                                            }
                                        } catch (e) {
                                            console.error("Failed to create Histogram MPV:", e);
                                        }
                                    }
                                }
                            }
                        }
                        
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 10
                            text: "히스토그램"
                            color: "white"
                            font.pixelSize: 14
                            z: 1
                        }
                    }
                    
                    // 벡터스코프 뷰
                    Rectangle {
                        id: vectorscopeView
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: parent.width / 2
                        height: parent.height
                        color: "#121212"
                        visible: vectorscopeCheck.checked
                        
                        // 벡터스코프 MPV 인스턴스
                        Loader {
                            id: vectorscopeMpvLoader
                            anchors.fill: parent
                            anchors.margins: 10
                            active: typeof hasMpvSupport !== "undefined" ? hasMpvSupport : false
                            
                            sourceComponent: Component {
                                Item {
                                    property var mpvPlayer: null
                                    
                                    Component.onCompleted: {
                                        try {
                                            // MPV 인스턴스 생성
                                            var component = Qt.createQmlObject(
                                                'import mpv 1.0; MpvObject { anchors.fill: parent }',
                                                this,
                                                "vectorscope_mpv"
                                            );
                                            
                                            if (component) {
                                                mpvPlayer = component;
                                                console.log("Vectorscope MPV created");
                                            }
                                        } catch (e) {
                                            console.error("Failed to create Vectorscope MPV:", e);
                                        }
                                    }
                                }
                            }
                        }
                        
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 10
                            text: "벡터스코프"
                            color: "white"
                            font.pixelSize: 14
                            z: 1
                        }
                    }
                }
            }
        }
    }
    
    // 스코프 업데이트 함수
    function updateScopes() {
        if (!videoArea || !videoArea.mpvSupported || currentFile === "") {
            statusText.text = "비디오가 로드되지 않았습니다";
            return;
        }
        
        if (!scopeLoader.item) {
            console.log("Scope loader item is null");
            return;
        }
        
        statusText.text = "";
        
        try {
            // 히스토그램 업데이트
            if (histogramCheck.checked) {
                var histogramMpvItem = scopeLoader.item.histogramMpvLoader.item;
                if (histogramMpvItem && histogramMpvItem.mpvPlayer) {
                    // 전체 경로 가져오기 (상대 경로가 문제가 될 수 있음)
                    var fullPath = currentFile;
                    if (!fullPath.startsWith("file:///")) {
                        fullPath = "file:///" + fullPath.replace(/\\/g, "/");
                    }
                    
                    // 히스토그램 필터 적용
                    histogramMpvItem.mpvPlayer.command(["loadfile", fullPath]);
                    
                    // 잠시 대기 후 필터 적용
                    Timer.setTimeout(function() {
                        histogramMpvItem.mpvPlayer.command(["vf", "set", "lavfi=histogram"]);
                        console.log("히스토그램 필터 적용됨:", fullPath);
                    }, 500);
                }
            }
            
            // 벡터스코프 업데이트
            if (vectorscopeCheck.checked) {
                var vectorscopeMpvItem = scopeLoader.item.vectorscopeMpvLoader.item;
                if (vectorscopeMpvItem && vectorscopeMpvItem.mpvPlayer) {
                    // 전체 경로 가져오기 (상대 경로가 문제가 될 수 있음)
                    var fullPath = currentFile;
                    if (!fullPath.startsWith("file:///")) {
                        fullPath = "file:///" + fullPath.replace(/\\/g, "/");
                    }
                    
                    // 벡터스코프 필터 적용
                    vectorscopeMpvItem.mpvPlayer.command(["loadfile", fullPath]);
                    
                    // 잠시 대기 후 필터 적용
                    Timer.setTimeout(function() {
                        vectorscopeMpvItem.mpvPlayer.command(["vf", "set", "lavfi=vectorscope"]);
                        console.log("벡터스코프 필터 적용됨:", fullPath);
                    }, 500);
                }
            }
        } catch (e) {
            console.error("Failed to update scopes:", e);
            statusText.text = "스코프 업데이트 실패: " + e;
        }
    }
}
