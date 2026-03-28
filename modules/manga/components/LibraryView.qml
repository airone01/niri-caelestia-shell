import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.config
import qs.services

Item {
    id: libraryView

    readonly property var c: Colours.tPalette
    readonly property string fontDisplay: Config.appearance.font.family.sans
    readonly property string fontBody: Config.appearance.font.family.sans

    // Emitted when the user taps an entry — parent handles navigation
    signal mangaSelected(string mangaId)

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; color: c.m3background }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Empty state ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Manga.libraryList.length === 0 && Manga.libraryLoaded

            Column {
                anchors.centerIn: parent
                spacing: 14

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⊡"
                    font.pixelSize: 44
                    color: c.m3outline
                    opacity: 0.3
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Your library is empty"
                    font.family: libraryView.fontDisplay
                    font.pixelSize: 15
                    color: c.m3onSurface
                    opacity: 0.45
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Open any manga and tap  + Library"
                    font.family: libraryView.fontBody
                    font.pixelSize: 11
                    color: c.m3onSurfaceVariant
                    opacity: 0.4
                    font.letterSpacing: 0.2
                }
            }
        }

        // ── Loading (first open before file is read) ──────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !Manga.libraryLoaded

            Column {
                anchors.centerIn: parent
                spacing: 16
                Rectangle {
                    width: 28; height: 28; radius: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.color: c.m3primary; border.width: 2
                    RotationAnimator on rotation {
                        from: 0; to: 360; duration: 800
                        loops: Animation.Infinite
                        running: parent.visible
                        easing.type: Easing.Linear
                    }
                }
            }
        }

        GridView {
            id: libGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Manga.libraryList.length > 0
            topMargin: 10
            leftMargin: 8
            rightMargin: 8
            bottomMargin: 10
            cellWidth: Math.floor((width - leftMargin - rightMargin) / 4)
            cellHeight: cellWidth * 1.72
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Manga.libraryList

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 3
                    color: c.m3primary
                    opacity: 0.45
                    radius: 2
                }
            }

            delegate: Item {
                width: libGrid.cellWidth
                height: libGrid.cellHeight

                readonly property var libEntry: modelData

                Rectangle {
                    id: libCard
                    anchors { fill: parent; margins: 5 }
                    radius: 12
                    color: c.m3surfaceContainer
                    clip: true

                    Image {
                        id: libCover
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: parent.height - libTitleBar.height - libLastReadBar.height
                        source: libEntry.coverUrl || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        Rectangle {
                            anchors.fill: parent
                            color: c.m3surfaceContainerHigh
                            visible: libCover.status !== Image.Ready
                            Text {
                                anchors.centerIn: parent
                                text: "◫"
                                font.pixelSize: 32
                                color: c.m3outline
                                opacity: 0.25
                            }
                        }

                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 48
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: c.m3surfaceContainer }
                            }
                        }
                    }

                    Rectangle {
                        id: libTitleBar
                        anchors {
                            bottom: libLastReadBar.top
                            left: parent.left; right: parent.right
                        }
                        height: libTitleText.implicitHeight + 10
                        color: c.m3surfaceContainer

                        Text {
                            id: libTitleText
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 10; rightMargin: 10
                            }
                            text: libEntry.title || ""
                            font.family: libraryView.fontBody
                            font.pixelSize: 11
                            font.letterSpacing: 0.2
                            color: c.m3onSurface
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            lineHeight: 1.3
                        }
                    }

                    Rectangle {
                        id: libLastReadBar
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 30
                        color: c.m3surfaceContainerHigh
                        radius: 12

                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.radius
                            color: parent.color
                        }

                        Row {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left; leftMargin: 10
                            }
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▶"
                                font.pixelSize: 7
                                color: libEntry.lastReadChapterNum
                                    ? c.m3primary
                                    : c.m3outline
                                opacity: libEntry.lastReadChapterNum ? 1 : 0.4
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: libEntry.lastReadChapterNum
                                    ? "Ch. " + libEntry.lastReadChapterNum
                                    : "Not started"
                                font.family: libraryView.fontBody
                                font.pixelSize: 10
                                font.letterSpacing: 0.4
                                color: libEntry.lastReadChapterNum
                                    ? c.m3onSurface
                                    : c.m3onSurfaceVariant
                                opacity: libEntry.lastReadChapterNum ? 0.85 : 0.45
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: c.m3primary
                        opacity: libCardArea.pressed
                            ? 0.16 : (libCardArea.containsMouse ? 0.07 : 0)
                        Behavior on opacity { NumberAnimation { duration: 130 } }
                    }

                    transform: Scale {
                        origin.x: libCard.width / 2
                        origin.y: libCard.height / 2
                        xScale: libCardArea.pressed ? 0.97 : 1.0
                        yScale: libCardArea.pressed ? 0.97 : 1.0
                        Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: libCardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Manga.fetchMangaDetail(libEntry.id)
                            libraryView.mangaSelected(libEntry.id)
                        }
                    }
                }
            }
        }
    }
}
