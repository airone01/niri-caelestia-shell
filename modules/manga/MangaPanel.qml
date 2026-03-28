import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import "./"

StyledWindow {
    id: root
    name: "manga"
    
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    implicitHeight: screen.height
    implicitWidth: 600
    
    anchors {
        top: true
        bottom: true
        left: true
    }
    
    focusable: true
    visible: false

    MangaReader {
        anchors.fill: parent
        visible: true
    }

    IpcHandler {
        target: "mangaReader"
        function toggle(): void {
            root.visible = !root.visible
        }
    }
}
