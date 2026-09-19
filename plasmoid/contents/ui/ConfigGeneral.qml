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
    property string cfg_slide1Left: Plasmoid.configuration.slide1Left
    property string cfg_slide1Right: Plasmoid.configuration.slide1Right
    property string cfg_slide2Left: Plasmoid.configuration.slide2Left
    property string cfg_slide2Right: Plasmoid.configuration.slide2Right
    property string cfg_slide3Left: Plasmoid.configuration.slide3Left
    property string cfg_slide3Right: Plasmoid.configuration.slide3Right

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
        { text: "Combat achievements", value: "combat_achievements" },
        { text: "XP milestones", value: "xp_milestones" },
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
        slide1LeftCombo.currentIndex = page.indexForContent(page.cfg_slide1Left)
        slide1RightCombo.currentIndex = page.indexForContent(page.cfg_slide1Right)
        slide2LeftCombo.currentIndex = page.indexForContent(page.cfg_slide2Left)
        slide2RightCombo.currentIndex = page.indexForContent(page.cfg_slide2Right)
        slide3LeftCombo.currentIndex = page.indexForContent(page.cfg_slide3Left)
        slide3RightCombo.currentIndex = page.indexForContent(page.cfg_slide3Right)
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
            Kirigami.FormData.label: "Rotate slides every (seconds):"
            from: 3
            to: 60
            stepSize: 1
        }

        Kirigami.Separator {
            Kirigami.FormData.label: "Slide content"
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: slide1LeftCombo
            Kirigami.FormData.label: "Slide 1 — left:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_slide1Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: slide1RightCombo
            Kirigami.FormData.label: "Slide 1 — right:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_slide1Right = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: slide2LeftCombo
            Kirigami.FormData.label: "Slide 2 — left:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_slide2Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: slide2RightCombo
            Kirigami.FormData.label: "Slide 2 — right:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_slide2Right = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: slide3LeftCombo
            Kirigami.FormData.label: "Slide 3 — left:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_slide3Left = page.contentModel[currentIndex].value
        }
        QQC2.ComboBox {
            id: slide3RightCombo
            Kirigami.FormData.label: "Slide 3 — right:"
            textRole: "text"
            model: page.contentModel
            onActivated: page.cfg_slide3Right = page.contentModel[currentIndex].value
        }
    }
}
