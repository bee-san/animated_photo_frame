import QtQuick 2.15
import QtTest 1.3

import "../contents/ui"
import "../contents/ui/MediaUtils.js" as MediaUtils

TestCase {
    id: testCase

    name: "MediaLibrary"

    Component {
        id: libraryComponent

        MediaLibrary {
        }
    }

    function createLibrary(properties) {
        const library = createTemporaryObject(libraryComponent, testCase, properties || {})

        verify(library !== null)
        wait(0)
        return library
    }

    function folderEntry(relativePath) {
        return JSON.stringify({
            "path": Qt.resolvedUrl(relativePath),
            "type": "folder"
        })
    }

    function fileEntry(relativePath) {
        return JSON.stringify({
            "path": Qt.resolvedUrl(relativePath),
            "type": "file"
        })
    }

    function waitForReload(library) {
        tryVerify(function() {
            return !library.loading
        }, 2000)
        wait(0)
    }

    function test_recursiveFolderScan_collectsSupportedMedia() {
        const library = createLibrary()

        library.pathList = [folderEntry("data/media")]
        library.reload()
        waitForReload(library)

        compare(library.count, 4)
        verify(library.contains(Qt.resolvedUrl("data/media/alpha.png")))
        verify(library.contains(Qt.resolvedUrl("data/media/beta.gif")))
        verify(library.contains(Qt.resolvedUrl("data/media/nested/gamma.webp")))
        verify(library.contains(Qt.resolvedUrl("data/media/nested/deeper/delta.jpg")))
        verify(!library.contains(Qt.resolvedUrl("data/media/ignore.txt")))
    }

    function test_sequentialGet_advancesInConfiguredOrder() {
        const library = createLibrary({
            "random": false
        })

        library.pathList = [
            fileEntry("data/media/alpha.png"),
            fileEntry("data/media/beta.gif")
        ]
        library.reload()
        waitForReload(library)

        let firstSource = ""
        let secondSource = ""

        library.get(function(source) {
            firstSource = source
        })
        library.get(function(source) {
            secondSource = source
        })

        compare(firstSource, MediaUtils.normalizeFileUrl(Qt.resolvedUrl("data/media/alpha.png")))
        compare(secondSource, MediaUtils.normalizeFileUrl(Qt.resolvedUrl("data/media/beta.gif")))
    }

    function test_historyAndFutureStacks_roundTripValues() {
        const library = createLibrary()

        library.pushHistory("file:///tmp/first.png")
        library.pushHistory("file:///tmp/second.png")
        compare(library.historyLength, 2)
        compare(library.popHistory(), "file:///tmp/second.png")
        compare(library.historyLength, 1)

        library.pushFuture("file:///tmp/third.png")
        compare(library.futureLength, 1)
        compare(library.popFuture(), "file:///tmp/third.png")
        compare(library.futureLength, 0)
    }

    function test_watch_preventsImmediateRandomRepeat_whenPossible() {
        const library = createLibrary({
            "random": true
        })

        library.pathList = [
            fileEntry("data/media/alpha.png"),
            fileEntry("data/media/beta.gif")
        ]
        library.reload()
        waitForReload(library)

        library.watch(Qt.resolvedUrl("data/media/alpha.png"))

        let nextSource = ""

        library.get(function(source) {
            nextSource = source
        })

        compare(nextSource, MediaUtils.normalizeFileUrl(Qt.resolvedUrl("data/media/beta.gif")))
    }
}
