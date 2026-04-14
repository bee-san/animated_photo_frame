import QtQuick

import "MediaUtils.js" as MediaUtils

Item {
    id: root

    property string source: ""
    property int fillMode: Image.PreserveAspectFit
    property bool smooth: true
    property bool enableAnimation: opacity > 0

    readonly property bool usesAnimatedImage: MediaUtils.isGifSource(source)
    readonly property int status: usesAnimatedImage ? animatedImage.status : stillImage.status

    function showSource(sourceUrl) {
        source = sourceUrl ? sourceUrl.toString() : ""
        refreshTimer.restart()
    }

    function clear() {
        source = ""
        stillImage.sourceSize.width = 0
        stillImage.sourceSize.height = 0
    }

    function refreshStillImageSourceSize() {
        if (!usesAnimatedImage) {
            stillImage.sourceSize.width = width
            stillImage.sourceSize.height = height
        }
    }

    onWidthChanged: refreshTimer.restart()
    onHeightChanged: refreshTimer.restart()
    onSourceChanged: refreshTimer.restart()

    Timer {
        id: refreshTimer

        interval: 250
        repeat: false
        onTriggered: root.refreshStillImageSourceSize()
    }

    Image {
        id: stillImage

        anchors.fill: parent
        visible: root.source !== "" && !root.usesAnimatedImage
        fillMode: root.fillMode
        cache: false
        asynchronous: true
        autoTransform: true
        smooth: root.smooth
        source: root.usesAnimatedImage ? "" : root.source
        sourceSize.width: width
        sourceSize.height: height
    }

    AnimatedImage {
        id: animatedImage

        anchors.fill: parent
        visible: root.source !== "" && root.usesAnimatedImage
        fillMode: root.fillMode
        cache: false
        asynchronous: true
        autoTransform: true
        smooth: root.smooth
        source: root.usesAnimatedImage ? root.source : ""
        playing: root.enableAnimation && visible
    }
}
