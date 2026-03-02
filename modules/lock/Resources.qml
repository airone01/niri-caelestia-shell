import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Appearance.padding.xl

    rowSpacing: Appearance.spacing.xxl
    columnSpacing: Appearance.spacing.xxl
    rows: 2
    columns: 2

    Ref {
        service: SystemUsage
    }

    Resource {
        Layout.topMargin: Appearance.padding.xl
        icon: "memory"
        value: SystemUsage.cpuPerc
        colour: Colours.palette.m3primary
    }

    Resource {
        Layout.topMargin: Appearance.padding.xl
        icon: "thermostat"
        value: Math.min(1, SystemUsage.cpuTemp / 90)
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Appearance.padding.xl
        icon: "memory_alt"
        value: SystemUsage.memPerc
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Appearance.padding.xl
        icon: "hard_disk"
        value: SystemUsage.storagePerc
        colour: Colours.palette.m3tertiary
    }

    component Resource: StyledRect {
        id: res

        required property string icon
        required property real value
        required property color colour

        Layout.fillWidth: true
        implicitHeight: width

        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        radius: Appearance.rounding.large

        CircularProgress {
            id: circ

            anchors.fill: parent
            value: res.value
            padding: Appearance.padding.xl * 3
            fgColour: res.colour
            bgColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
            strokeWidth: width < 200 ? Appearance.padding.sm : Appearance.padding.md
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: res.icon
            color: res.colour
            font.pointSize: (circ.arcRadius * 0.7) || 1
            font.weight: 600
        }

        Behavior on value {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }
    }
}
