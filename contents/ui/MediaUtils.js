.pragma library

var supportedImageSuffixes = [
    "png",
    "jpg",
    "jpeg",
    "gif",
    "webp",
    "bmp",
    "avif",
    "svg",
    "svgz"
]

function stringValue(value) {
    if (value === null || value === undefined) {
        return ""
    }

    return value.toString()
}

function stripFragmentAndQuery(value) {
    let normalized = stringValue(value)
    const hashIndex = normalized.indexOf("#")
    const queryIndex = normalized.indexOf("?")
    let cutIndex = -1

    if (hashIndex >= 0 && queryIndex >= 0) {
        cutIndex = Math.min(hashIndex, queryIndex)
    } else if (hashIndex >= 0) {
        cutIndex = hashIndex
    } else if (queryIndex >= 0) {
        cutIndex = queryIndex
    }

    if (cutIndex >= 0) {
        normalized = normalized.slice(0, cutIndex)
    }

    return normalized
}

function normalizeFileUrl(value) {
    let normalized = stripFragmentAndQuery(stringValue(value).trim())

    if (normalized === "") {
        return ""
    }

    if (normalized.startsWith("file://")) {
        return normalized
    }

    if (normalized.startsWith("/")) {
        return "file://" + encodeURI(normalized).replace(/#/g, "%23")
    }

    return normalized
}

function localPathFromUrl(value) {
    const normalized = normalizeFileUrl(value)

    if (normalized.startsWith("file://")) {
        return decodeURIComponent(normalized.slice(7))
    }

    return normalized
}

function fileSuffix(value) {
    const normalized = stripFragmentAndQuery(localPathFromUrl(value))
    const lastDotIndex = normalized.lastIndexOf(".")

    if (lastDotIndex < 0 || lastDotIndex === normalized.length - 1) {
        return ""
    }

    return normalized.slice(lastDotIndex + 1).toLowerCase()
}

function isGifSource(value) {
    return fileSuffix(value) === "gif"
}

function isSupportedMediaSource(value) {
    return supportedImageSuffixes.indexOf(fileSuffix(value)) >= 0
}

function urlEquals(firstValue, secondValue) {
    return normalizeFileUrl(firstValue) === normalizeFileUrl(secondValue)
}

function parsePathEntry(entry) {
    let candidate = entry

    if (typeof entry === "string") {
        try {
            candidate = JSON.parse(entry)
        } catch (error) {
            return null
        }
    }

    if (!candidate || candidate.path === null || candidate.path === undefined) {
        return null
    }

    const normalizedPath = normalizeFileUrl(candidate.path)

    if (normalizedPath === "") {
        return null
    }

    let type = stringValue(candidate.type).toLowerCase()

    if (type !== "file" && type !== "folder") {
        type = isSupportedMediaSource(normalizedPath) ? "file" : "folder"
    }

    return {
        "path": normalizedPath,
        "type": type
    }
}
