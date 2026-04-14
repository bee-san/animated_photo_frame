import QtQuick 2.15
import QtTest 1.3

import "../contents/ui/MediaUtils.js" as MediaUtils

TestCase {
    name: "MediaUtils"

    function test_normalizeFileUrl_wrapsLocalPaths() {
        compare(
            MediaUtils.normalizeFileUrl("/tmp/example file.gif"),
            "file:///tmp/example%20file.gif"
        )
    }

    function test_isGifSource_ignoresCaseAndQuery() {
        verify(MediaUtils.isGifSource("file:///tmp/clip.GIF?size=large#frame"))
        verify(!MediaUtils.isGifSource("file:///tmp/clip.webp"))
    }

    function test_isSupportedMediaSource_filtersByExtension() {
        verify(MediaUtils.isSupportedMediaSource("file:///tmp/picture.png"))
        verify(MediaUtils.isSupportedMediaSource("file:///tmp/animation.gif"))
        verify(!MediaUtils.isSupportedMediaSource("file:///tmp/readme.txt"))
    }

    function test_parsePathEntry_normalizesAndPreservesType() {
        const parsed = MediaUtils.parsePathEntry(JSON.stringify({
            "path": "/tmp/photo.jpg",
            "type": "file"
        }))

        compare(parsed.path, "file:///tmp/photo.jpg")
        compare(parsed.type, "file")
    }
}
