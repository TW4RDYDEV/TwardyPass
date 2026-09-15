import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../theme"
import "../components"

WorkbenchPage {
    id: page
    property var result: bridge.analysis
    property var breach: bridge.breach
    property string exportKind: "json"
    function analyze() {
        bridge.updateAnalyzer(password.text, context.text);
    }
    function changed() {
        bridge.invalidateAnalyzer();
        analysisTimer.restart();
    }
    Timer {
        id: analysisTimer
        interval: 180
        onTriggered: page.analyze()
    }
    Connections {
        target: bridge
        function onSensitiveCleared() {
            password.clear();
            context.clear();
            analysisTimer.stop();
            reportDialog.close();
        }
    }
    FileDialog {
        id: reportDialog
        title: "Export sanitized report"
        fileMode: FileDialog.SaveFile
        defaultSuffix: page.exportKind
        nameFilters: page.exportKind === "pdf" ? ["PDF report (*.pdf)"] : ["JSON report (*.json)"]
        onAccepted: bridge.exportReport(selectedFile, page.exportKind)
    }
    AppCard {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            SectionHeader {
                text: "Understand your password"
                Layout.fillWidth: true
            }
            StatusBadge {
                text: "LOCAL / LIVE"
            }
        }
        PasswordField {
            id: password
            objectName: "analyzerPassword"
            Layout.fillWidth: true
            placeholderText: "Enter a password to analyze"
            onTextChanged: page.changed()
        }
        RowLayout {
            Layout.fillWidth: true
            AppText {
                text: password.characterCount + " characters  /  8,192 limit"
                color: Theme.muted
                font.pixelSize: 11
            }
            Item {
                Layout.fillWidth: true
            }
            AppText {
                text: "Masked by default · Never saved"
                color: Theme.muted
                font.pixelSize: 11
            }
        }
        AppTextField {
            id: context
            objectName: "analyzerContext"
            Layout.fillWidth: true
            maximumLength: 2048
            placeholderText: "Personal context (optional): name, username, company — separated by commas"
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            onTextChanged: page.changed()
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 18
        AppCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            SectionHeader {
                text: "Security score"
            }
            ScoreRing {
                Layout.alignment: Qt.AlignHCenter
                score: page.result.score || 0
                classification: page.result.classification || "Waiting"
                tone: page.result.color || Theme.muted
            }
            AppText {
                Layout.fillWidth: true
                text: "Pattern-aware analysis, with full-length structural checks."
                color: Theme.muted
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }
        AppCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            RowLayout {
                Layout.fillWidth: true
                SectionHeader {
                    text: "Security DNA"
                    Layout.fillWidth: true
                }
                StatusBadge {
                    text: "5 AXES"
                    tone: Theme.secondary
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                SecurityRadar {
                    objectName: "securityRadar"
                    Layout.fillWidth: true
                    Layout.minimumWidth: 190
                    Layout.preferredWidth: 220
                    dna: page.result.dna || ({})
                    breachState: page.breach.status
                }
                ColumnLayout {
                    Layout.preferredWidth: 165
                    spacing: 14
                    Repeater {
                        model: ["Length", "Unpredictability", "Pattern safety", "Character diversity", "Breach safety"]
                        ColumnLayout {
                            required property int index
                            required property string modelData
                            Layout.fillWidth: true
                            spacing: 3
                            AppText {
                                text: (index + 1) + "  " + modelData
                                color: Theme.muted
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                            AppText {
                                property var dna: page.result.dna || ({})
                                text: index === 4 ? (page.breach.status === "clear" ? "100 / NO MATCH" : page.breach.status === "compromised" ? "0 / COMPROMISED" : "UNKNOWN") : [dna.length || 0, dna.unpredictability || 0, dna.patternSafety || 0, dna.characterMix || 0][index] + " / 100"
                                color: index === 4 && page.breach.status !== "clear" ? Theme.warning : Theme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
            AppText {
                Layout.fillWidth: true
                text: "An unchecked breach axis stays open and unknown."
                color: Theme.muted
                font.pixelSize: 12
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "LENGTH"
            value: (page.result.length || 0) + " chars"
        }
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "CHARACTER-SPACE ESTIMATE"
            value: (page.result.entropy || 0) + " bits"
        }
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "GUESSES / LOG10"
            value: "10^" + (page.result.guesses_log10 || 0)
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 18
        AppCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            SectionHeader {
                text: "Pattern inspector"
            }
            AppText {
                Layout.fillWidth: true
                text: "Finding types and explanations only. Matched text stays private."
                color: Theme.muted
                font.pixelSize: 12
            }
            Repeater {
                model: page.result.findings || []
                FindingChip {
                    required property var modelData
                    Layout.fillWidth: true
                    finding: modelData
                }
            }
            AppText {
                visible: !(page.result.length)
                text: "Enter a password to inspect its structure."
                color: Theme.muted
            }
        }
        AppCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            SectionHeader {
                text: "Attack resistance"
            }
            Repeater {
                model: [
                    {
                        name: "ONLINE · 100 / HOUR",
                        key: "onlineThrottled"
                    },
                    {
                        name: "ONLINE · 10 / SECOND",
                        key: "onlineUnthrottled"
                    },
                    {
                        name: "OFFLINE · SLOW HASH",
                        key: "offlineSlow"
                    },
                    {
                        name: "OFFLINE · FAST HASH",
                        key: "offlineFast"
                    }
                ]
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 5
                    AppText {
                        text: modelData.name
                        color: Theme.muted
                        font.pixelSize: 10
                        Layout.fillWidth: true
                    }
                    AppText {
                        text: (page.result.attack || ({}))[modelData.key] || "—"
                        font.pixelSize: 18
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.border
                        Layout.topMargin: 5
                        Layout.bottomMargin: 5
                    }
                }
            }
            AppText {
                Layout.fillWidth: true
                text: "Approximations, not guarantees. Above 128 characters, zxcvbn uses a bounded sample. Character-space entropy assumes random selection."
                color: Theme.muted
                font.pixelSize: 12
            }
        }
    }
    AppCard {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            SectionHeader {
                text: "Breach intelligence"
                Layout.fillWidth: true
            }
            StatusBadge {
                text: ({
                        idle: "NOT CHECKED",
                        checking: "CHECKING",
                        clear: "NO MATCH FOUND",
                        compromised: "COMPROMISED",
                        error: "NETWORK ERROR"
                    })[page.breach.status] || "NOT CHECKED"
                tone: page.breach.status === "compromised" ? Theme.danger : page.breach.status === "clear" ? Theme.success : Theme.muted
            }
        }
        AppText {
            text: page.breach.message || "Not checked"
            Layout.fillWidth: true
        }
        AppText {
            text: "Manual HIBP lookup. Only a five-character hash prefix leaves this device; responses are padded and compared locally."
            color: Theme.muted
            Layout.fillWidth: true
            font.pixelSize: 12
        }
        RowLayout {
            AppButton {
                objectName: "checkBreachButton"
                text: bridge.offlineOnly ? "Offline mode enabled" : "Check breach exposure"
                primary: true
                enabled: page.result.length > 0 && page.breach.status !== "checking" && !bridge.offlineOnly
                onClicked: bridge.checkBreach()
            }
            AppButton {
                text: "Export JSON"
                enabled: page.result.length > 0
                onClicked: {
                    page.exportKind = "json";
                    reportDialog.open();
                }
            }
            AppButton {
                text: "Export PDF"
                enabled: page.result.length > 0
                onClicked: {
                    page.exportKind = "pdf";
                    reportDialog.open();
                }
            }
        }
    }
    AppCard {
        Layout.fillWidth: true
        SectionHeader {
            text: "Recommendations"
        }
        Repeater {
            model: page.result.recommendations || []
            AppText {
                required property string modelData
                Layout.fillWidth: true
                text: "•  " + modelData
                color: Theme.muted
            }
        }
    }
}
