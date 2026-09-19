import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_username: usernameField.text
    property string cfg_period: Plasmoid.configuration.period
    property alias cfg_skillTopN: skillTopNSpin.value
    property alias cfg_bossTopN: bossTopNSpin.value
    property alias cfg_cardWidth: cardWidthSpin.value
    property alias cfg_cardHeight: cardHeightSpin.value
    property alias cfg_historyDays: historyDaysSpin.value
    property alias cfg_rotationSeconds: rotationSecondsSpin.value
    property alias cfg_panelCount: panelCountSpin.value
    property string cfg_panel1Left: Plasmoid.configuration.panel1Left
    property string cfg_panel1Right: Plasmoid.configuration.panel1Right
    property string cfg_panel2Left: Plasmoid.configuration.panel2Left
    property string cfg_panel2Right: Plasmoid.configuration.panel2Right
    property string cfg_panel3Left: Plasmoid.configuration.panel3Left
    property string cfg_panel3Right: Plasmoid.configuration.panel3Right
    property string cfg_panel4Left: Plasmoid.configuration.panel4Left
    property string cfg_panel4Right: Plasmoid.configuration.panel4Right
    property string cfg_panel5Left: Plasmoid.configuration.panel5Left
    property string cfg_panel5Right: Plasmoid.configuration.panel5Right
    property alias cfg_minDropValue: minDropValueSpin.value
    property alias cfg_dropsSortByValue: dropsSortByValueCheck.checked
    property alias cfg_showRank: showRankCheck.checked

    readonly property var periodModel: [
        { text: "Day", value: "day" },
        { text: "Week", value: "week" },
        { text: "Month", value: "month" },
        { text: "Year", value: "year" },
        { text: "Total (all time)", value: "all_time" }
    ]

    readonly property var contentModel: [
        { text: "Top skills", value: "skills" },
        { text: "Top bosses", value: "bosses" },
        { text: "Valuable drops", value: "valuable_drops" },
        { text: "New collection log items", value: "new_items" },
        { text: "Combat achievements completed", value: "combat_achievements" },
        { text: "Combat achievement progress", value: "ca_progress" },
        { text: "XP milestones", value: "xp_milestones" },
        { text: "Level ups", value: "level_up" },
        { text: "Quests completed", value: "quest_completed" },
        { text: "Achievement diary tiers", value: "diary_tier_completed" },
        { text: "None (blank)", value: "none" }
    ]

    function indexForContent(value) {
        for (let i = 0; i < page.contentModel.length; i++) {
            if (page.contentModel[i].value === value) return i
        }
        return page.contentModel.length - 1
    }

    Component.onCompleted: {
        for (let i = 0; i < page.periodModel.length; i++) {
            if (page.periodModel[i].value === page.cfg_period) {
                periodCombo.currentIndex = i
                break
            }
        }
        panel1LeftCombo.currentIndex = page.indexForContent(page.cfg_panel1Left)
        panel1RightCombo.currentIndex = page.indexForContent(page.cfg_panel1Right)
        panel2LeftCombo.currentIndex = page.indexForContent(page.cfg_panel2Left)
        panel2RightCombo.currentIndex = page.indexForContent(page.cfg_panel2Right)
        panel3LeftCombo.currentIndex = page.indexForContent(page.cfg_panel3Left)
        panel3RightCombo.currentIndex = page.indexForContent(page.cfg_panel3Right)
        panel4LeftCombo.currentIndex = page.indexForContent(page.cfg_panel4Left)
        panel4RightCombo.currentIndex = page.indexForContent(page.cfg_panel4Right)
        panel5LeftCombo.currentIndex = page.indexForContent(page.cfg_panel5Left)
        panel5RightCombo.currentIndex = page.indexForContent(page.cfg_panel5Right)
    }

    Kirigami.FormLayout {
        QQC2.TextField {
            id: usernameField
            Kirigami.FormData.label: "RSN:"
        }

        QQC2.ComboBox {
            id: periodCombo
            Kirigami.FormData.label: "Period:"
            textRole: "text"
            model: page.periodModel
            onActivated: page.cfg_period = page.periodModel[currentIndex].value
        }

        QQC2.SpinBox {
            id: skillTopNSpin
            Kirigami.FormData.label: "Top N skills:"
            from: 1
            to: 12
        }

        QQC2.SpinBox {
            id: bossTopNSpin
            Kirigami.FormData.label: "Top N bosses:"
            from: 1
            to: 12
        }

        QQC2.SpinBox {
            id: cardWidthSpin
            Kirigami.FormData.label: "Widget width (px):"
            from: 300
            to: 1920
            stepSize: 10
        }

        QQC2.SpinBox {
            id: cardHeightSpin
            Kirigami.FormData.label: "Widget height (px):"
            from: 60
            to: 400
            stepSize: 5
        }

        QQC2.SpinBox {
            id: historyDaysSpin
            Kirigami.FormData.label: "History graph range (days):"
            from: 7
            to: 365
            stepSize: 1
        }

        QQC2.SpinBox {
            id: rotationSecondsSpin
            Kirigami.FormData.label: "Rotate panels every (seconds):"
            from: 3
            to: 60
            stepSize: 1
        }

        Kirigami.Separator {
            Kirigami.FormData.label: "Panels"
            Kirigami.FormData.isSection: true
        }

        QQC2.SpinBox {
            id: panelCountSpin
            Kirigami.FormData.label: "How many panels to rotate through:"
            from: 1
            to: 5
        }

        QQC2.ComboBox {
            id: panel1LeftCombo
            Kirigami.FormData.label: "Panel 1 — left:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_panel1Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel1RightCombo
            Kirigami.FormData.label: "Panel 1 — right:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_panel1Right = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel2LeftCombo
            Kirigami.FormData.label: "Panel 2 — left:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 2
            onActivated: page.cfg_panel2Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel2RightCombo
            Kirigami.FormData.label: "Panel 2 — right:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 2
            onActivated: page.cfg_panel2Right = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel3LeftCombo
            Kirigami.FormData.label: "Panel 3 — left:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 3
            onActivated: page.cfg_panel3Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel3RightCombo
            Kirigami.FormData.label: "Panel 3 — right:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 3
            onActivated: page.cfg_panel3Right = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel4LeftCombo
            Kirigami.FormData.label: "Panel 4 — left:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 4
            onActivated: page.cfg_panel4Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel4RightCombo
            Kirigami.FormData.label: "Panel 4 — right:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 4
            onActivated: page.cfg_panel4Right = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel5LeftCombo
            Kirigami.FormData.label: "Panel 5 — left:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 5
            onActivated: page.cfg_panel5Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: panel5RightCombo
            Kirigami.FormData.label: "Panel 5 — right:"
            textRole: "text"
            model: page.contentModel
            visible: page.cfg_panelCount >= 5
            onActivated: page.cfg_panel5Right = page.contentModel[currentIndex].value
        }

        Kirigami.Separator {
            Kirigami.FormData.label: "Other"
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showRankCheck
            Kirigami.FormData.label: "Overall column:"
            text: "Show hiscores rank"
        }

        QQC2.SpinBox {
            id: minDropValueSpin
            Kirigami.FormData.label: "Minimum valuable drop value (gp):"
            from: 0
            to: 2000000000
            stepSize: 100000
            editable: true
        }

        QQC2.CheckBox {
            id: dropsSortByValueCheck
            text: "Sort valuable drops by value instead of date"
        }
    }
}
