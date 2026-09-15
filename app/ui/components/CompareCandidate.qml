import QtQuick
import QtQuick.Layouts
import "../theme"

AppCard {
    id: candidate
    property string name: "A"
    property var result: ({})
    property int best: -1
    property alias password: input.text
    function analyze() {
        result = input.text ? bridge.analyzePassword(input.text, "") : ({});
    }
    function clear() {
        input.clear();
        result = ({});
    }
    border.color: result.length && result.score === best ? Theme.accent : Theme.border
    padding: 16
    RowLayout {
        Layout.fillWidth: true
        Layout.minimumHeight: 28
        AppText {
            text: "CANDIDATE " + candidate.name
            color: Theme.muted
            font.pixelSize: 11
            Layout.fillWidth: true
        }
        StatusBadge {
            visible: !!candidate.result.length && candidate.result.score === candidate.best
            text: "TOP"
        }
    }
    PasswordField {
        id: input
        objectName: "compare" + candidate.name
        Layout.fillWidth: true
        placeholderText: "Candidate " + candidate.name
        onTextChanged: candidate.result = ({})
    }
    RowLayout {
        AppButton {
            text: "Analyze"
            enabled: input.text.length > 0
            onClicked: candidate.analyze()
        }
        AppButton {
            text: "Clear"
            onClicked: candidate.clear()
        }
    }
    ScoreRing {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 210
        implicitHeight: 210
        score: candidate.result.score || 0
        classification: candidate.result.classification || "Waiting"
        tone: candidate.result.color || Theme.muted
    }
    AppText {
        text: "Length: " + (candidate.result.length || 0) + " characters"
        Layout.fillWidth: true
    }
    AppText {
        text: "Entropy estimate: " + (candidate.result.entropy || 0) + " bits"
        Layout.fillWidth: true
    }
    AppText {
        text: "Pattern safety: " + ((candidate.result.dna || ({})).patternSafety || 0) + " / 100"
        Layout.fillWidth: true
    }
    AppText {
        text: "Offline / fast hash: " + ((candidate.result.attack || ({})).offlineFast || "—")
        color: Theme.muted
        Layout.fillWidth: true
    }
    Connections {
        target: bridge
        function onSensitiveCleared() {
            candidate.clear();
        }
    }
}
