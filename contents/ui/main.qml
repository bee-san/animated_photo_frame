/*
 * Based on the stock KDE Picture Frame applet, with a local media library
 * backend and AnimatedImage support for GIF files.
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

PlasmoidItem {
    id: main

    MediaLibrary {
        id: items

        pathList: plasmoid.configuration.pathList || []
        random: plasmoid.configuration.randomize
    }

    switchWidth: Kirigami.Units.gridUnit * 5
    switchHeight: Kirigami.Units.gridUnit * 5

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.configurationRequired: !hasItems
    Plasmoid.icon: activeSource.length > 0 ? activeSource : "settings-configure"

    width: Kirigami.Units.gridUnit * 23
    height: Kirigami.Units.gridUnit * 15

    property string activeSource: ""
    property string transitionSource: ""

    readonly property bool pause: plasmoid.configuration.pauseOnMouseOver
        && (fullRepresentationItem?.overlayMouseArea?.containsMouse ?? false)
    readonly property int itemCount: items.count
    readonly property bool hasItems: itemCount > 0
    readonly property bool isTransitioning: fullRepresentationItem?.faderAnimation?.running ?? false

    onActiveSourceChanged: items.watch(activeSource)

    onHasItemsChanged: {
        if (!hasItems) {
            clearDisplayedSource()
            return
        }

        if (activeSource === "") {
            nextItem()
        }
    }

    Connections {
        target: items

        function onMediaReloaded() {
            if (!main.hasItems) {
                main.clearDisplayedSource()
                return
            }

            if (main.activeSource === "" || !items.contains(main.activeSource)) {
                main.clearDisplayedSource()
                main.nextItem()
            }
        }
    }

    function clearDisplayedSource() {
        activeSource = ""
        transitionSource = ""

        if (fullRepresentationItem) {
            fullRepresentationItem.showSourceImmediately("")
        }
    }

    function nextItem() {
        if (!hasItems || isTransitioning) {
            return
        }

        if (itemCount > 1 && activeSource !== "") {
            items.pushHistory(activeSource)
        }

        if (items.futureLength > 0) {
            setActiveSource(items.popFuture())
            return
        }

        items.get(
            function(filePath) {
                setActiveSource(filePath)
            },
            function() {
            }
        )
    }

    function previousItem() {
        if (items.historyLength === 0 || isTransitioning) {
            return
        }

        if (activeSource !== "") {
            items.pushFuture(activeSource)
        }

        setActiveSource(items.popHistory())
    }

    function setActiveSource(source) {
        const normalizedSource = source ? source.toString() : ""

        if (normalizedSource === "") {
            return
        }

        transitionSource = normalizedSource

        if (!fullRepresentationItem || activeSource === "") {
            activeSource = normalizedSource

            if (fullRepresentationItem) {
                fullRepresentationItem.showSourceImmediately(normalizedSource)
            }

            return
        }

        if (normalizedSource === activeSource) {
            return
        }

        fullRepresentationItem.beginTransition(normalizedSource)
    }

    Timer {
        id: nextTimer

        interval: plasmoid.configuration.interval * 1000
        repeat: true
        running: hasItems && !pause && !isTransitioning
        onTriggered: nextItem()
    }

    fullRepresentation: Item {
        id: representation

        property alias faderAnimation: faderAnimation
        property alias overlayMouseArea: overlayMouseArea

        property Item frontLayer: image1
        property Item bufferLayer: image2

        function showSourceImmediately(source) {
            faderAnimation.stop()
            frontLayer.showSource(source)
            frontLayer.opacity = source === "" ? 0 : 1
            bufferLayer.clear()
            bufferLayer.opacity = 0
        }

        function beginTransition(source) {
            if (source === "") {
                return
            }

            bufferLayer.showSource(source)
            bufferLayer.opacity = 0
            faderAnimation.restart()
        }

        Item {
            id: itemView
            anchors.fill: parent

            Item {
                id: imageView

                visible: hasItems
                anchors.fill: parent

                HoverHandler {
                    enabled: Plasmoid.configuration.leftClickOpenImage && main.activeSource !== ""
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    enabled: Plasmoid.configuration.leftClickOpenImage && main.activeSource !== ""
                    onTapped: Qt.openUrlExternally(main.activeSource)
                }

                MediaLayer {
                    id: image2

                    anchors.fill: parent
                    z: representation.frontLayer === image2 ? 1 : 0
                    fillMode: plasmoid.configuration.fillMode
                }

                MediaLayer {
                    id: image1

                    anchors.fill: parent
                    z: representation.frontLayer === image1 ? 1 : 0
                    fillMode: plasmoid.configuration.fillMode
                }
            }
        }

        SequentialAnimation {
            id: faderAnimation

            ParallelAnimation {
                OpacityAnimator {
                    target: representation.frontLayer
                    from: 1
                    to: 0
                    duration: Kirigami.Units.veryLongDuration
                }

                OpacityAnimator {
                    target: representation.bufferLayer
                    from: 0
                    to: 1
                    duration: Kirigami.Units.veryLongDuration
                }
            }

            ScriptAction {
                script: {
                    const previousFrontLayer = representation.frontLayer
                    representation.frontLayer = representation.bufferLayer
                    representation.bufferLayer = previousFrontLayer
                    representation.bufferLayer.clear()
                    representation.bufferLayer.opacity = 0
                    main.activeSource = main.transitionSource
                }
            }
        }

        Item {
            id: overlay

            anchors.fill: parent
            visible: hasItems
            opacity: overlayMouseArea.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                }
            }

            PlasmaComponents3.Button {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                enabled: items.historyLength > 0 && !isTransitioning
                visible: main.itemCount > 1
                icon.name: "arrow-left"
                onClicked: {
                    nextTimer.stop()
                    previousItem()
                }
            }

            PlasmaComponents3.Button {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                enabled: hasItems && !isTransitioning
                visible: main.itemCount > 1
                icon.name: "arrow-right"
                onClicked: {
                    nextTimer.stop()
                    nextItem()
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: Kirigami.Units.smallSpacing

                PlasmaComponents3.Button {
                    icon.name: "document-preview"
                    onClicked: Qt.openUrlExternally(main.activeSource)
                }
            }

            MouseArea {
                id: overlayMouseArea

                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true

                onPressed: mouse => mouse.accepted = false
                onDoubleClicked: mouse => mouse.accepted = false
            }
        }

        PlasmaExtras.PlaceholderMessage {
            id: configNeededPlaceholder

            property bool fitsInWidget: implicitWidth <= parent.width && implicitHeight <= parent.height

            anchors.centerIn: parent
            visible: !hasItems && fitsInWidget
            iconName: "viewimage-symbolic"
            text: i18nc("@info placeholdermessage if no media loaded", "No media selected")

            helpfulAction: Kirigami.Action {
                icon.name: "insert-image-symbolic"
                text: i18nc("@action:button opens settings dialog", "Choose media…")
                onTriggered: Plasmoid.internalAction("configure").trigger()
            }
        }

        PlasmaComponents3.Button {
            anchors.centerIn: parent

            visible: !hasItems && !configNeededPlaceholder.fitsInWidget
            icon.name: "insert-image-symbolic"
            text: i18nc("@action:button opens settings dialog", "Choose media…")
            onClicked: Plasmoid.internalAction("configure").trigger()
        }
    }
}
