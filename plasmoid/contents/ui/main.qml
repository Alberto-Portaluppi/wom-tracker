pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt.labs.platform as Platform
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property var womData: ({})
    readonly property string homeDir:
        Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation)
        .toString().replace("file://", "")
    readonly property string cachePath: root.homeDir + "/.cache/wom-tracker/data.json"
    readonly property string fetchScriptPath: root.homeDir + "/.local/share/wom-tracker/fetch.py"
    readonly property string applyConfigScriptPath: root.homeDir + "/.local/share/wom-tracker/apply_config.py"

    readonly property bool hasData: Object.keys(root.womData).length > 0
    readonly property var overallData: root.womData.overall ? root.womData.overall : null
    readonly property var skillsData: root.womData.top_skills ? root.womData.top_skills : []
    readonly property var bossesData: root.womData.top_bosses ? root.womData.top_bosses : []

    function fmt(n) {
        if (n === undefined || n === null) return "-"
        return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    }

    function refreshNow() {
        actionSource.connectSource(
            "python3 '" + root.fetchScriptPath + "' >/dev/null 2>&1; cat '" + root.cachePath + "'"
        )
    }

    function saveConfig(payload) {
        const encoded = Qt.btoa(JSON.stringify(payload))
        actionSource.connectSource(
            "python3 '" + root.applyConfigScriptPath + "' '" + encoded + "' && python3 '"
            + root.fetchScriptPath + "' >/dev/null 2>&1; cat '" + root.cachePath + "'"
        )
    }

    // Plasmoid.configuration is backed by contents/config/main.xml, edited through
    // the widget's native "Configure..." dialog (same one that has About/Shortcuts).
    // Whenever it changes, mirror it into config.json so the systemd-timer-driven
    // fetch.py (a separate process) picks up the same settings, then refetch.
    property bool configLoaded: false
    Component.onCompleted: configReadyTimer.start()
    Timer {
        id: configReadyTimer
        interval: 200
        onTriggered: root.configLoaded = true
    }

    function syncConfigAndRefresh() {
        root.saveConfig({
            username: Plasmoid.configuration.username,
            period: Plasmoid.configuration.period,
            skill_top_n: Plasmoid.configuration.skillTopN,
            boss_top_n: Plasmoid.configuration.bossTopN,
            card_width: Plasmoid.configuration.cardWidth,
            card_height: Plasmoid.configuration.cardHeight
        })
    }

    Timer {
        id: configSyncDebounce
        interval: 300
        onTriggered: root.syncConfigAndRefresh()
    }

    Connections {
        target: Plasmoid.configuration
        function onUsernameChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onPeriodChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onSkillTopNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onBossTopNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onCardWidthChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onCardHeightChanged() { if (root.configLoaded) configSyncDebounce.restart() }
    }

    // A fresh applet instance starts with KCFG defaults ("YourRSN", etc.), which
    // would clobber the real config.json the first time the native config dialog
    // is used. Seed Plasmoid.configuration from whatever data.json already has
    // as soon as we see it, but only once (guarded by the "YourRSN" sentinel).
    function applyWomData(json) {
        root.womData = json
        if (Plasmoid.configuration.username === "YourRSN" && json.username) {
            Plasmoid.configuration.username = json.username
            if (json.period) Plasmoid.configuration.period = json.period
            if (json.skill_top_n) Plasmoid.configuration.skillTopN = json.skill_top_n
            if (json.boss_top_n) Plasmoid.configuration.bossTopN = json.boss_top_n
            if (json.card_width) Plasmoid.configuration.cardWidth = json.card_width
            if (json.card_height) Plasmoid.configuration.cardHeight = json.card_height
        }
    }

    Plasma5Support.DataSource {
        id: cacheSource
        engine: "executable"
        interval: 60000
        connectedSources: ["cat " + root.cachePath]
        onNewData: function (sourceName, data) {
            const stdout = data["stdout"] ? data["stdout"].toString() : ""
            if (stdout.length > 0) {
                try {
                    root.applyWomData(JSON.parse(stdout))
                } catch (e) {
                    console.warn("wom-tracker: invalid cache json", e)
                }
            }
        }
    }

    // One-shot commands: manual refresh and config sync both land here so
    // their result (fresh data.json) applies immediately.
    Plasma5Support.DataSource {
        id: actionSource
        engine: "executable"
        onNewData: function (sourceName, data) {
            const stdout = data["stdout"] ? data["stdout"].toString() : ""
            if (stdout.length > 0) {
                try {
                    root.applyWomData(JSON.parse(stdout))
                } catch (e) {
                    console.warn("wom-tracker: action produced no valid json", e)
                }
            }
            disconnectSource(sourceName)
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh now"
            icon.name: "view-refresh"
            onTriggered: root.refreshNow()
        }
    ]

    fullRepresentation: Item {
        id: card
        Layout.preferredWidth: root.womData.card_width ? root.womData.card_width : 978
        Layout.preferredHeight: root.womData.card_height ? root.womData.card_height : 92
        Layout.minimumWidth: root.womData.card_width ? root.womData.card_width : 978
        Layout.minimumHeight: root.womData.card_height ? root.womData.card_height : 92

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            opacity: 0.96
        }

        Text {
            anchors.centerIn: parent
            visible: !root.hasData
            text: "Waiting for wom-tracker data…"
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 16
            visible: root.hasData

            // -- Overall --
            ColumnLayout {
                Layout.preferredWidth: 230
                Layout.fillHeight: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Kirigami.Heading {
                        level: 4
                        text: root.womData.username ? root.womData.username : "RSN"
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: root.womData.updated_at
                            ? Qt.formatDateTime(new Date(root.womData.updated_at), "dd/MM hh:mm")
                            : ""
                        font.pixelSize: 9
                        color: Kirigami.Theme.disabledTextColor
                    }
                }
                Text {
                    text: "Overall"
                    font.pixelSize: 11
                    color: Kirigami.Theme.disabledTextColor
                }
                Text {
                    text: root.overallData ? (root.fmt(root.overallData.experience) + " xp") : "-"
                    font.pixelSize: 17
                    font.bold: true
                    color: Kirigami.Theme.textColor
                }

                Item { Layout.fillHeight: true }
            }

            Kirigami.Separator { Layout.fillHeight: true }

            // -- Top skills by XP gained --
            ColumnLayout {
                Layout.preferredWidth: 350
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: root.womData.skills_header ? root.womData.skills_header : "Top 3 Skills"
                    font.pixelSize: 11
                    color: Kirigami.Theme.disabledTextColor
                }

                Repeater {
                    model: root.skillsData
                    delegate: RowLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: (index + 1) + ". " + modelData.name
                            font.pixelSize: 13
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                        }
                        Text {
                            text: (root.womData.value_prefix !== undefined ? root.womData.value_prefix : "+")
                                + root.fmt(modelData.value) + " " + modelData.suffix
                            font.pixelSize: 13
                            font.bold: true
                            color: Kirigami.Theme.positiveTextColor
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            Kirigami.Separator { Layout.fillHeight: true }

            // -- Top bosses by kill count --
            ColumnLayout {
                Layout.preferredWidth: 290
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: root.womData.bosses_header ? root.womData.bosses_header : "Top 3 Bosses"
                    font.pixelSize: 11
                    color: Kirigami.Theme.disabledTextColor
                }

                Repeater {
                    model: root.bossesData
                    delegate: RowLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: (index + 1) + ". " + modelData.name
                            font.pixelSize: 13
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                        }
                        Text {
                            text: (root.womData.value_prefix !== undefined ? root.womData.value_prefix : "+")
                                + root.fmt(modelData.value) + " " + modelData.suffix
                            font.pixelSize: 13
                            font.bold: true
                            color: Kirigami.Theme.neutralTextColor
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
