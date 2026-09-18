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

    readonly property var periodModel: [
        { text: "Day", value: "day" },
        { text: "Week", value: "week" },
        { text: "Month", value: "month" },
        { text: "Year", value: "year" },
        { text: "Total (all time)", value: "all_time" }
    ]

    Component.onCompleted: {
        for (let i = 0; i < page.periodModel.length; i++) {
            if (page.periodModel[i].value === page.cfg_period) {
                periodCombo.currentIndex = i
                break
            }
        }
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
            to: 5
        }

        QQC2.SpinBox {
            id: bossTopNSpin
            Kirigami.FormData.label: "Top N bosses:"
            from: 1
            to: 5
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
    }
}
