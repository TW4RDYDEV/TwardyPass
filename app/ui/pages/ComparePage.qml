import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

WorkbenchPage {
    id: page
    property int best: Math.max(a.result.length ? a.result.score : -1, b.result.length ? b.result.score : -1, c.result.length ? c.result.score : -1)
    AppText {
        text: "Three candidates. One local comparison. The highest score is highlighted, including ties."
        Layout.fillWidth: true
        color: Theme.muted
    }
    RowLayout {
        AppButton {
            text: "Analyze all"
            primary: true
            onClicked: {
                a.analyze();
                b.analyze();
                c.analyze();
            }
        }
        AppButton {
            text: "Clear compare"
            onClicked: {
                a.clear();
                b.clear();
                c.clear();
            }
        }
        StatusBadge {
            text: "NO NETWORK"
            tone: Theme.success
        }
    }
    Row {
        id: candidates
        Layout.fillWidth: true
        spacing: 14
        property real candidateWidth: (width - 2 * spacing) / 3
        CompareCandidate {
            id: a
            objectName: "candidateA"
            width: candidates.candidateWidth
            name: "A"
            best: page.best
        }
        CompareCandidate {
            id: b
            objectName: "candidateB"
            width: candidates.candidateWidth
            name: "B"
            best: page.best
        }
        CompareCandidate {
            id: c
            objectName: "candidateC"
            width: candidates.candidateWidth
            name: "C"
            best: page.best
        }
    }
    AppCard {
        Layout.fillWidth: true
        SectionHeader {
            text: "Comparison matrix"
        }
        Repeater {
            model: ["Candidate", "Score", "Length", "Entropy estimate", "Pattern safety", "Offline / fast hash"]
            Row {
                id: matrixRow
                required property int index
                required property string modelData
                Layout.fillWidth: true
                spacing: 8
                AppText {
                    text: matrixRow.modelData
                    width: 170
                    color: Theme.muted
                }
                Repeater {
                    model: [a.result, b.result, c.result]
                    AppText {
                        required property int index
                        required property var modelData
                        objectName: "matrixCell" + matrixRow.index + "_" + index
                        width: Math.max(0, (matrixRow.width - 170 - 24) / 3)
                        text: matrixRow.index === 0 ? ["A", "B", "C"][index] : !modelData.length ? "—" : ["", modelData.score, modelData.length, modelData.entropy + " bits", (modelData.dna || ({})).patternSafety, (modelData.attack || ({})).offlineFast][matrixRow.index]
                    }
                }
            }
        }
        AppText {
            text: "Scores and crack times are approximate. Compare Lab never performs breach lookups."
            color: Theme.muted
            Layout.fillWidth: true
            font.pixelSize: 12
        }
    }
}
