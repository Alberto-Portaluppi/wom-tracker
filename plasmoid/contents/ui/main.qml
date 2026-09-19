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
    readonly property string historyScriptPath: root.homeDir + "/.local/share/wom-tracker/history_export.py"

    readonly property bool hasData: Object.keys(root.womData).length > 0
    readonly property var overallData: root.womData.overall ? root.womData.overall : null
    readonly property var skillsData: root.womData.top_skills ? root.womData.top_skills : []
    readonly property var bossesData: root.womData.top_bosses ? root.womData.top_bosses : []
    readonly property var valuableDrops: root.womData.valuable_drops ? root.womData.valuable_drops : []
    readonly property var newItems: root.womData.new_items ? root.womData.new_items : []
    readonly property var combatAchievements: root.womData.combat_achievements ? root.womData.combat_achievements : []
    readonly property var xpMilestones: root.womData.xp_milestones ? root.womData.xp_milestones : []
    readonly property var levelUps: root.womData.level_ups ? root.womData.level_ups : []
    readonly property var questsCompleted: root.womData.quests_completed ? root.womData.quests_completed : []
    readonly property var diaryTiers: root.womData.diary_tiers ? root.womData.diary_tiers : []
    readonly property var caProgress: root.womData.ca_progress ? root.womData.ca_progress : []

    // The two side columns cycle through 1-5 user-configurable panels (each
    // with independent left/right content) like a display sign, so someone
    // who doesn't care about e.g. quests or diaries can just run 1 panel of
    // (skills, bosses) forever, while someone who wants everything can add
    // panels up to 5. Skills/bosses sub-page on the same global tick using
    // their own item count, so if skill_top_n/boss_top_n is above
    // rowsPerPage, whichever panel shows them cycles through all of their
    // pages over multiple full rotations.
    readonly property int rowsPerPage: 3
    readonly property int rotationSeconds: Plasmoid.configuration.rotationSeconds
    property int rotationPage: 0
    readonly property int panelCount: Math.max(1, Math.min(5, Plasmoid.configuration.panelCount))
    readonly property int slideIndex: root.rotationPage % root.panelCount

    // Every content type can now have more items than fit in one page (each
    // count is independently configurable), so this is generic: whichever
    // panel shows it sub-pages through the rest on the same global rotation
    // tick, using that content's own item count for the page math.
    function paginatedContent(items, header, color, colorName) {
        const pageCount = Math.max(1, Math.ceil(items.length / root.rowsPerPage))
        const subPage = root.rotationPage % pageCount
        const offset = subPage * root.rowsPerPage
        const pageSuffix = pageCount > 1 ? " (" + (subPage + 1) + "/" + pageCount + ")" : ""
        return {
            items: items.slice(offset, offset + root.rowsPerPage),
            header: header + pageSuffix,
            offset: offset,
            color: color,
            colorName: colorName,
            isNone: false
        }
    }

    function contentFor(key) {
        switch (key) {
        case "skills":
            return root.paginatedContent(
                root.skillsData,
                root.womData.skills_header ? root.womData.skills_header : "Top Skills",
                Kirigami.Theme.positiveTextColor, false
            )
        case "bosses":
            return root.paginatedContent(
                root.bossesData,
                root.womData.bosses_header ? root.womData.bosses_header : "Top Bosses",
                Kirigami.Theme.neutralTextColor, false
            )
        case "valuable_drops":
            return root.paginatedContent(root.valuableDrops, "Valuable Drops", Kirigami.Theme.positiveTextColor, false)
        case "new_items": {
            // No natural "value" column for these (it's just "you got it"), so
            // the item name itself is the colored part instead of a value.
            const cl = root.womData.collection_log
            const clSuffix = cl ? " (" + cl.obtained + "/" + cl.total + ")" : ""
            return root.paginatedContent(root.newItems, "New Collection Log Items" + clSuffix, Kirigami.Theme.neutralTextColor, true)
        }
        case "combat_achievements":
            return root.paginatedContent(root.combatAchievements, "Combat Achievements", Kirigami.Theme.neutralTextColor, false)
        case "ca_progress":
            return root.paginatedContent(root.caProgress, "Combat Achievement Progress", Kirigami.Theme.neutralTextColor, false)
        case "xp_milestones":
            return root.paginatedContent(root.xpMilestones, "XP Milestones", Kirigami.Theme.positiveTextColor, false)
        case "level_up":
            return root.paginatedContent(root.levelUps, "Level Ups", Kirigami.Theme.positiveTextColor, false)
        case "quest_completed":
            // No natural "value" column (it's just "completed"), so the quest
            // name itself is the colored part, same treatment as new_items.
            return root.paginatedContent(root.questsCompleted, "Quests Completed", Kirigami.Theme.positiveTextColor, true)
        case "diary_tier_completed":
            return root.paginatedContent(root.diaryTiers, "Achievement Diary Tiers", Kirigami.Theme.neutralTextColor, false)
        default:
            return { items: [], header: "", offset: 0, color: Kirigami.Theme.disabledTextColor, colorName: false, isNone: true }
        }
    }

    readonly property var allPanelKeys: [
        [Plasmoid.configuration.panel1Left, Plasmoid.configuration.panel1Right],
        [Plasmoid.configuration.panel2Left, Plasmoid.configuration.panel2Right],
        [Plasmoid.configuration.panel3Left, Plasmoid.configuration.panel3Right],
        [Plasmoid.configuration.panel4Left, Plasmoid.configuration.panel4Right],
        [Plasmoid.configuration.panel5Left, Plasmoid.configuration.panel5Right]
    ]
    readonly property var slideKeys: root.allPanelKeys.slice(0, root.panelCount)
    readonly property var leftContent: root.contentFor(root.slideKeys[root.slideIndex][0])
    readonly property var rightContent: root.contentFor(root.slideKeys[root.slideIndex][1])
    readonly property var leftItems: root.leftContent.items
    readonly property var rightItems: root.rightContent.items
    readonly property string leftHeader: root.leftContent.header
    readonly property string rightHeader: root.rightContent.header
    readonly property int leftPageOffset: root.leftContent.offset

    // Always runs: even with a single panel, its own content might have more
    // items than fit on one page and need to sub-page on this same tick.
    Timer {
        interval: root.rotationSeconds * 1000
        running: true
        repeat: true
        onTriggered: root.rotationPage = root.rotationPage + 1
    }

    property var historyPoints: []
    readonly property int historyDays: Plasmoid.configuration.historyDays
    onHistoryPointsChanged: historyCanvas.requestPaint()

    // Respects the system locale (e.g. "." for pt_BR, "," for en_US) instead
    // of hardcoding a separator, since this widget isn't only used by
    // Portuguese speakers. Non-numeric values (dates, tier names) pass through.
    function fmt(n) {
        if (n === undefined || n === null) return "-"
        if (typeof n === "number") return n.toLocaleString(Qt.locale(), 'f', 0)
        return n.toString()
    }

    // Activity items (drops, CAs, new items, milestones) carry a date_label
    // and read better with "18/09 - Name" than a rank number, since they're
    // a timeline, not a top-N ranking like skills/bosses are.
    function rowLabel(modelData, index, offset) {
        if (modelData.date_label !== undefined) {
            return modelData.date_label + " - " + modelData.name
        }
        return (offset + index + 1) + ". " + modelData.name
    }

    function escapeHtml(text) {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    // Same "date - name" shape as rowLabel, but with just the name colored
    // and bold (date stays plain) — used when colorName is set, since there's
    // no value column to carry the color instead.
    function rowLabelRich(modelData, color) {
        return modelData.date_label + " - <b><font color=\"" + color + "\">"
            + root.escapeHtml(modelData.name) + "</font></b>"
    }

    // Describes the actual span covered by the returned points, not the
    // requested window — WOM may not have snapshots going back the full
    // requested range (e.g. a freshly-tracked account), so this stays honest.
    function formatSpan(ms) {
        const hours = ms / 3600000
        if (hours < 1) return "in the last " + Math.max(1, Math.round(ms / 60000)) + " min"
        if (hours < 48) return "in the last " + Math.round(hours) + "h"
        return "in the last " + Math.round(hours / 24) + " days"
    }

    function historySummaryText() {
        if (root.historyPoints.length < 2) return ""
        const first = root.historyPoints[0]
        const last = root.historyPoints[root.historyPoints.length - 1]
        const gained = last.xp - first.xp
        const sign = gained >= 0 ? "+" : ""
        const spanMs = new Date(last.ts).getTime() - new Date(first.ts).getTime()
        return sign + root.fmt(gained) + " xp " + root.formatSpan(spanMs)
    }

    function toggleHistoryPopup() {
        if (historyDialog.visible) {
            historyDialog.visible = false
            return
        }
        historyDialog.visible = true
        historySource.connectSource("python3 '" + root.historyScriptPath + "' " + root.historyDays)
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
            card_height: Plasmoid.configuration.cardHeight,
            min_drop_value: Plasmoid.configuration.minDropValue,
            drops_sort_by_value: Plasmoid.configuration.dropsSortByValue,
            valuable_drops_n: Plasmoid.configuration.valuableDropsN,
            new_items_n: Plasmoid.configuration.newItemsN,
            combat_achievements_n: Plasmoid.configuration.combatAchievementsN,
            ca_progress_n: Plasmoid.configuration.caProgressN,
            xp_milestones_n: Plasmoid.configuration.xpMilestonesN,
            level_up_n: Plasmoid.configuration.levelUpN,
            quest_completed_n: Plasmoid.configuration.questCompletedN,
            diary_tier_n: Plasmoid.configuration.diaryTierN
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
        function onMinDropValueChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onDropsSortByValueChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onValuableDropsNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onNewItemsNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onCombatAchievementsNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onCaProgressNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onXpMilestonesNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onLevelUpNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onQuestCompletedNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
        function onDiaryTierNChanged() { if (root.configLoaded) configSyncDebounce.restart() }
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
            if (json.min_drop_value) Plasmoid.configuration.minDropValue = json.min_drop_value
            if (json.drops_sort_by_value) Plasmoid.configuration.dropsSortByValue = json.drops_sort_by_value
            if (json.valuable_drops_n) Plasmoid.configuration.valuableDropsN = json.valuable_drops_n
            if (json.new_items_n) Plasmoid.configuration.newItemsN = json.new_items_n
            if (json.combat_achievements_n) Plasmoid.configuration.combatAchievementsN = json.combat_achievements_n
            if (json.ca_progress_n) Plasmoid.configuration.caProgressN = json.ca_progress_n
            if (json.xp_milestones_n) Plasmoid.configuration.xpMilestonesN = json.xp_milestones_n
            if (json.level_up_n) Plasmoid.configuration.levelUpN = json.level_up_n
            if (json.quest_completed_n) Plasmoid.configuration.questCompletedN = json.quest_completed_n
            if (json.diary_tier_n) Plasmoid.configuration.diaryTierN = json.diary_tier_n
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

    Plasma5Support.DataSource {
        id: historySource
        engine: "executable"
        onNewData: function (sourceName, data) {
            const stdout = data["stdout"] ? data["stdout"].toString() : ""
            if (stdout.length > 0) {
                try {
                    const parsed = JSON.parse(stdout)
                    root.historyPoints = parsed.points ? parsed.points : []
                } catch (e) {
                    console.warn("wom-tracker: invalid history json", e)
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

    PlasmaCore.Dialog {
        id: historyDialog
        visualParent: root
        hideOnWindowDeactivate: true

        mainItem: ColumnLayout {
            id: historyForm
            width: 600
            height: implicitHeight
            spacing: 8

            Kirigami.Heading {
                level: 5
                text: "XP History"
                Layout.fillWidth: true
            }

            Text {
                Layout.fillWidth: true
                text: root.historySummaryText()
                color: Kirigami.Theme.positiveTextColor
                font.bold: true
                visible: text.length > 0
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                visible: root.historyPoints.length < 2
                text: "Not enough data yet — check back after a few more fetch cycles."
                color: Kirigami.Theme.disabledTextColor
            }

            Canvas {
                id: historyCanvas
                Layout.preferredWidth: 580
                Layout.preferredHeight: 280
                visible: root.historyPoints.length >= 2

                // "Nice" round step (1/2/5 x 10^n) for the Y-axis gridlines,
                // so labels read like 462,000,000 instead of arbitrary values.
                function niceStep(range, targetTicks) {
                    if (range <= 0) return 1
                    const rough = range / targetTicks
                    const magnitude = Math.pow(10, Math.floor(Math.log(rough) / Math.LN10))
                    const residual = rough / magnitude
                    let niceResidual
                    if (residual > 5) niceResidual = 10
                    else if (residual > 2) niceResidual = 5
                    else if (residual > 1) niceResidual = 2
                    else niceResidual = 1
                    return niceResidual * magnitude
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const w = width
                    const h = height
                    const points = root.historyPoints
                    if (points.length < 2) return

                    let minX, maxX, minY, maxY
                    for (let i = 0; i < points.length; i++) {
                        const x = new Date(points[i].ts).getTime()
                        const y = points[i].xp
                        if (minX === undefined || x < minX) minX = x
                        if (maxX === undefined || x > maxX) maxX = x
                        if (minY === undefined || y < minY) minY = y
                        if (maxY === undefined || y > maxY) maxY = y
                    }
                    if (maxX === minX) maxX += 1

                    const yStep = historyCanvas.niceStep(Math.max(maxY - minY, 1), 5)
                    const niceMinY = Math.floor(minY / yStep) * yStep
                    const niceMaxY = Math.ceil(maxY / yStep) * yStep

                    const leftMargin = 80
                    const rightMargin = 12
                    const topMargin = 10
                    const bottomMargin = 22

                    function px(x) { return leftMargin + (x - minX) / (maxX - minX) * (w - leftMargin - rightMargin) }
                    function py(y) { return h - bottomMargin - (y - niceMinY) / (niceMaxY - niceMinY) * (h - topMargin - bottomMargin) }

                    // horizontal gridlines + rounded XP labels
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                    ctx.lineWidth = 1
                    ctx.font = "10px sans-serif"
                    ctx.fillStyle = Kirigami.Theme.disabledTextColor
                    ctx.textAlign = "right"
                    ctx.textBaseline = "middle"
                    for (let gy = niceMinY; gy <= niceMaxY + yStep * 0.001; gy += yStep) {
                        const yy = py(gy)
                        ctx.beginPath()
                        ctx.moveTo(leftMargin, yy)
                        ctx.lineTo(w - rightMargin, yy)
                        ctx.stroke()
                        ctx.fillText(root.fmt(Math.round(gy)), leftMargin - 8, yy)
                    }

                    // a handful of evenly-spaced date labels along the X axis
                    const tickCount = 4
                    ctx.textAlign = "center"
                    ctx.textBaseline = "top"
                    for (let i = 0; i <= tickCount; i++) {
                        const tx = minX + (maxX - minX) * (i / tickCount)
                        ctx.fillText(Qt.formatDateTime(new Date(tx), "dd/MM"), px(tx), h - bottomMargin + 5)
                    }

                    // the XP line, drawn over the grid
                    ctx.strokeStyle = Kirigami.Theme.positiveTextColor
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    for (let j = 0; j < points.length; j++) {
                        const xx = px(new Date(points[j].ts).getTime())
                        const yy = py(points[j].xp)
                        if (j === 0) ctx.moveTo(xx, yy)
                        else ctx.lineTo(xx, yy)
                    }
                    ctx.stroke()

                    ctx.lineTo(px(maxX), h - bottomMargin)
                    ctx.lineTo(px(minX), h - bottomMargin)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(
                        Kirigami.Theme.positiveTextColor.r,
                        Kirigami.Theme.positiveTextColor.g,
                        Kirigami.Theme.positiveTextColor.b,
                        0.12
                    )
                    ctx.fill()
                }
            }
        }
    }

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

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleHistoryPopup()
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
                Text {
                    text: (root.overallData && root.overallData.rank !== undefined && root.overallData.rank !== null)
                        ? "Rank #" + root.fmt(root.overallData.rank)
                        : ""
                    font.pixelSize: 10
                    color: Kirigami.Theme.disabledTextColor
                    visible: Plasmoid.configuration.showRank && text.length > 0
                }

                Item { Layout.fillHeight: true }
            }

            Kirigami.Separator { Layout.fillHeight: true }

            // -- Left column of the current rotating panel --
            ColumnLayout {
                Layout.preferredWidth: 350
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: root.leftHeader
                    font.pixelSize: 11
                    color: Kirigami.Theme.disabledTextColor
                }

                Text {
                    text: "No data yet"
                    font.pixelSize: 12
                    color: Kirigami.Theme.disabledTextColor
                    visible: root.leftItems.length === 0 && !root.leftContent.isNone
                }

                Repeater {
                    model: root.leftItems
                    delegate: RowLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            textFormat: root.leftContent.colorName ? Text.StyledText : Text.PlainText
                            text: root.leftContent.colorName
                                ? root.rowLabelRich(modelData, root.leftContent.color)
                                : root.rowLabel(modelData, index, root.leftPageOffset)
                            font.pixelSize: 13
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.prefix + root.fmt(modelData.value) + " " + modelData.suffix
                            font.pixelSize: 13
                            font.bold: true
                            color: root.leftContent.color
                            visible: !root.leftContent.colorName
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            Kirigami.Separator { Layout.fillHeight: true }

            // -- Right column of the current rotating panel --
            ColumnLayout {
                Layout.preferredWidth: 290
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: root.rightHeader
                    font.pixelSize: 11
                    color: Kirigami.Theme.disabledTextColor
                }

                Text {
                    text: "No data yet"
                    font.pixelSize: 12
                    color: Kirigami.Theme.disabledTextColor
                    visible: root.rightItems.length === 0 && !root.rightContent.isNone
                }

                Repeater {
                    model: root.rightItems
                    delegate: RowLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            textFormat: root.rightContent.colorName ? Text.StyledText : Text.PlainText
                            text: root.rightContent.colorName
                                ? root.rowLabelRich(modelData, root.rightContent.color)
                                : root.rowLabel(modelData, index, 0)
                            font.pixelSize: 13
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.prefix + root.fmt(modelData.value) + " " + modelData.suffix
                            font.pixelSize: 13
                            font.bold: true
                            color: root.rightContent.color
                            visible: !root.rightContent.colorName
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
