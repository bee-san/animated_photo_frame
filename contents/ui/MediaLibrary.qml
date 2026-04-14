import QtQuick
import Qt.labs.folderlistmodel

import "MediaUtils.js" as MediaUtils

Item {
    id: root

    visible: false

    property var pathList: []
    property bool random: true
    property var mediaItems: []
    property var historyItems: []
    property var futureItems: []
    property bool loading: false
    property string lastError: ""

    readonly property int count: mediaItems.length
    readonly property int historyLength: historyItems.length
    readonly property int futureLength: futureItems.length

    property string _lastWatchedSource: ""
    property int _sequentialIndex: -1
    property int _scanGeneration: 0
    property int _currentScanGeneration: 0
    property string _currentFolder: ""
    property var _pendingFolders: []
    property var _pendingFolderKeys: ({})
    property var _pendingMediaKeys: ({})
    property var _pendingResults: []

    signal mediaReloaded()

    onPathListChanged: reloadTimer.restart()

    Component.onCompleted: reloadTimer.start()

    Timer {
        id: reloadTimer

        interval: 0
        repeat: false
        onTriggered: root.reload()
    }

    Timer {
        id: scanPollTimer

        interval: 25
        repeat: false

        onTriggered: {
            if (root._currentFolder === "") {
                return
            }

            if (scanner.status === FolderListModel.Ready) {
                root._consumeCurrentFolder()
            } else {
                scanPollTimer.restart()
            }
        }
    }

    FolderListModel {
        id: scanner

        folder: ""
        showDirs: true
        showFiles: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        sortReversed: false

        onFolderChanged: scanPollTimer.restart()

        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                scanPollTimer.restart()
            }
        }
    }

    function clear() {
        _scanGeneration += 1
        _currentScanGeneration = _scanGeneration
        _currentFolder = ""
        _pendingFolders = []
        _pendingFolderKeys = ({})
        _pendingMediaKeys = ({})
        _pendingResults = []
        _lastWatchedSource = ""
        _sequentialIndex = -1
        loading = false
        lastError = ""
        scanner.folder = ""
        mediaItems = []
        historyItems = []
        futureItems = []
        mediaReloaded()
    }

    function reload() {
        _scanGeneration += 1
        _currentScanGeneration = _scanGeneration
        _currentFolder = ""
        _pendingFolders = []
        _pendingFolderKeys = ({})
        _pendingMediaKeys = ({})
        _pendingResults = []
        _lastWatchedSource = ""
        _sequentialIndex = -1
        lastError = ""
        historyItems = []
        futureItems = []
        scanner.folder = ""

        const entries = _parsedEntries()

        for (let index = 0; index < entries.length; index += 1) {
            const entry = entries[index]

            if (entry.type === "folder") {
                _enqueueFolder(entry.path)
            } else {
                _appendMedia(entry.path)
            }
        }

        loading = _pendingFolders.length > 0

        if (!loading) {
            _finishReload()
            return
        }

        _scanNextFolder()
    }

    function contains(source) {
        return indexOfSource(source) >= 0
    }

    function indexOfSource(source) {
        const normalizedSource = MediaUtils.normalizeFileUrl(source)

        for (let index = 0; index < mediaItems.length; index += 1) {
            if (MediaUtils.urlEquals(mediaItems[index], normalizedSource)) {
                return index
            }
        }

        return -1
    }

    function watch(source) {
        _lastWatchedSource = MediaUtils.normalizeFileUrl(source)
    }

    function get(success, error) {
        if (mediaItems.length === 0) {
            lastError = loading ? "Media library is still loading." : "No media available."

            if (error) {
                error(lastError)
            }

            return ""
        }

        const source = random ? _nextRandomSource() : _nextSequentialSource()
        _lastWatchedSource = source

        if (success) {
            success(source)
        }

        return source
    }

    function pushHistory(source) {
        const normalizedSource = MediaUtils.normalizeFileUrl(source)

        if (normalizedSource === "") {
            return
        }

        const nextHistory = historyItems.slice()
        nextHistory.push(normalizedSource)
        historyItems = nextHistory
    }

    function popHistory() {
        if (historyItems.length === 0) {
            return ""
        }

        const nextHistory = historyItems.slice()
        const value = nextHistory.pop()
        historyItems = nextHistory
        return value
    }

    function pushFuture(source) {
        const normalizedSource = MediaUtils.normalizeFileUrl(source)

        if (normalizedSource === "") {
            return
        }

        const nextFuture = futureItems.slice()
        nextFuture.push(normalizedSource)
        futureItems = nextFuture
    }

    function popFuture() {
        if (futureItems.length === 0) {
            return ""
        }

        const nextFuture = futureItems.slice()
        const value = nextFuture.pop()
        futureItems = nextFuture
        return value
    }

    function _parsedEntries() {
        const parsedEntries = []
        const configuredEntries = pathList || []

        for (let index = 0; index < configuredEntries.length; index += 1) {
            const parsedEntry = MediaUtils.parsePathEntry(configuredEntries[index])

            if (parsedEntry) {
                parsedEntries.push(parsedEntry)
            }
        }

        return parsedEntries
    }

    function _enqueueFolder(source) {
        const normalizedSource = MediaUtils.normalizeFileUrl(source)

        if (normalizedSource === "") {
            return
        }

        if (_pendingFolderKeys[normalizedSource]) {
            return
        }

        _pendingFolderKeys[normalizedSource] = true
        _pendingFolders.push(normalizedSource)
    }

    function _appendMedia(source) {
        const normalizedSource = MediaUtils.normalizeFileUrl(source)

        if (normalizedSource === "" || !MediaUtils.isSupportedMediaSource(normalizedSource)) {
            return
        }

        if (_pendingMediaKeys[normalizedSource]) {
            return
        }

        _pendingMediaKeys[normalizedSource] = true
        _pendingResults.push(normalizedSource)
    }

    function _scanNextFolder() {
        if (_currentScanGeneration !== _scanGeneration) {
            return
        }

        if (_pendingFolders.length === 0) {
            _finishReload()
            return
        }

        _currentFolder = _pendingFolders.shift()
        scanner.folder = _currentFolder
    }

    function _consumeCurrentFolder() {
        if (_currentScanGeneration !== _scanGeneration || _currentFolder === "") {
            return
        }

        for (let row = 0; row < scanner.count; row += 1) {
            const fileUrl = MediaUtils.normalizeFileUrl(scanner.get(row, "fileUrl"))

            if (scanner.get(row, "fileIsDir")) {
                _enqueueFolder(fileUrl)
            } else {
                _appendMedia(fileUrl)
            }
        }

        _currentFolder = ""
        _scanNextFolder()
    }

    function _finishReload() {
        if (_currentScanGeneration !== _scanGeneration) {
            return
        }

        loading = false
        _currentFolder = ""
        scanner.folder = ""
        mediaItems = _pendingResults.slice()
        mediaReloaded()
    }

    function _nextSequentialSource() {
        if (mediaItems.length === 0) {
            return ""
        }

        _sequentialIndex = (_sequentialIndex + 1) % mediaItems.length
        return mediaItems[_sequentialIndex]
    }

    function _nextRandomSource() {
        if (mediaItems.length === 0) {
            return ""
        }

        if (mediaItems.length === 1) {
            return mediaItems[0]
        }

        const currentSource = _lastWatchedSource
        let candidateIndex = Math.floor(Math.random() * mediaItems.length)
        let candidate = mediaItems[candidateIndex]

        if (!MediaUtils.urlEquals(candidate, currentSource)) {
            return candidate
        }

        if (candidateIndex >= mediaItems.length - 1) {
            candidateIndex = 0
        } else {
            candidateIndex += 1
        }

        return mediaItems[candidateIndex]
    }
}
