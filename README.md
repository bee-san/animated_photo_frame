# Animated Photo Frame

A Plasma 6 plasmoid that works like KDE's Picture Frame widget, but also plays animated GIFs instead of showing them as static frames.

## Features

- Displays local images and GIFs
- Recursively scans configured folders
- Supports slideshow intervals, random order, and previous/next navigation
- Keeps the stock Picture Frame config keys for easier migration

## Install

From this repository:

```bash
kpackagetool6 --type Plasma/Applet --install .
```

To update an existing install:

```bash
kpackagetool6 --type Plasma/Applet --upgrade .
```

Then add the `Animated Photo Frame` widget from Plasma's widget picker.

## Development

The package root is the repository root. Main files:

- `contents/ui/main.qml`
- `contents/ui/MediaLibrary.qml`
- `contents/ui/MediaLayer.qml`
- `contents/ui/ConfigMedia.qml`
- `contents/ui/ConfigBehavior.qml`

Basic headless checks:

```bash
python3 - <<'PY'
import os, sys
os.environ["QT_QPA_PLATFORM"] = "offscreen"
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlEngine, QQmlComponent
from PyQt6.QtCore import QUrl
app = QGuiApplication(sys.argv)
engine = QQmlEngine()
component = QQmlComponent(engine, QUrl.fromLocalFile("contents/ui/main.qml"))
print(component.status().name)
for err in component.errors():
    print(err.toString())
PY
```
