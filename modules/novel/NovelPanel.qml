import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import "./"

StyledWindow {
    id: root
    name: "novel"
    
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    implicitHeight: screen.height
    implicitWidth: 600
    
    anchors {
        top: true
        bottom: true
        right: true
    }
    
    focusable: true
    visible: false

    NovelReader {
        anchors.fill: parent
        visible: true
    }

    IpcHandler {
        target: "novelReader"
        function toggle(): void {
            root.visible = !root.visible
        }
    }
}
