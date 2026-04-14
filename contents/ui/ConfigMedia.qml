/*
 * Based on the stock KDE Picture Frame configuration UI.
 */

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.extras as PlasmaExtras

KCM.ScrollViewKCM {
    signal configurationChanged

    property int cfg_interval: 10
    property int cfg_intervalDefault: 10
    property bool cfg_randomize: true
    property bool cfg_randomizeDefault: true
    property bool cfg_pauseOnMouseOver: true
    property bool cfg_pauseOnMouseOverDefault: true
    property bool cfg_leftClickOpenImage: true
    property bool cfg_leftClickOpenImageDefault: true
    property bool cfg_showCountdown: true
    property bool cfg_showCountdownDefault: true
    property int cfg_fillMode: Image.PreserveAspectFit
    property int cfg_fillModeDefault: Image.PreserveAspectFit
    property var cfg_pathList: []
    property var cfg_pathListDefault: []

    actions: [
        Kirigami.Action {
            text: i18nc("@action:button", "Add Folder…")
            icon.name: "folder-new"
            onTriggered: folderDialog.visible = true
        },
        Kirigami.Action {
            text: i18nc("@action:button", "Add Files…")
            icon.name: "document-new"
            onTriggered: fileDialog.visible = true
        }
    ]

    function addPath(pathObject) {
        pathModel.append(pathObject)
        cfg_pathList.push(JSON.stringify(pathObject))
        cfg_pathListChanged()
    }

    function removePath(index) {
        if (pathModel.count === 0) {
            return
        }

        pathModel.remove(index)
        cfg_pathList.splice(index, 1)
        cfg_pathListChanged()
    }

    Component.onCompleted: {
        const list = plasmoid.configuration.pathList || []

        cfg_pathList = []

        for (const entry of list) {
            addPath(JSON.parse(entry))
        }
    }

    view: ListView {
        id: pathsList

        model: ListModel {
            id: pathModel
        }

        delegate: Kirigami.SwipeListItem {
            id: pathDelegate

            width: pathsList.width

            contentItem: QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                text: String(model.path).replace("file://", "")
                textFormat: Text.PlainText
            }

            actions: [
                Kirigami.Action {
                    icon.name: "list-remove"
                    tooltip: i18nc("@action:button tooltip on icon-only button", "Remove path")
                    onTriggered: removePath(model.index)
                }
            ]
        }

        PlasmaExtras.PlaceholderMessage {
            anchors.centerIn: parent
            visible: pathModel.count === 0
            iconName: "insert-image-symbolic"
            text: i18nc("@info placeholdermessage if no paths set", "No media configured")
            explanation: i18nc("@info placeholdermessage explanation", "Add files or folders to display them in the widget.")
        }

        FileDialog {
            id: fileDialog

            title: i18nc("@title:window", "Choose Files")
            currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
            fileMode: FileDialog.OpenFiles

            onAccepted: {
                for (let index = 0; index < selectedFiles.length; index += 1) {
                    addPath({
                        "path": selectedFiles[index],
                        "type": "file"
                    })
                }
            }
        }

        FolderDialog {
            id: folderDialog

            visible: false
            title: i18nc("@title:window", "Choose a Folder")
            currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]

            onAccepted: {
                addPath({
                    "path": selectedFolder,
                    "type": "folder"
                })
            }
        }
    }
}
