import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components"

WorkbenchPage {
    id: page
    function config() {
        return {
            minLength: minLength.value,
            minScore: minScore.value,
            minEntropy: minEntropy.value,
            uppercase: upper.checked,
            lowercase: lower.checked,
            digits: digits.checked,
            symbols: symbols.checked,
            rejectPatterns: patterns.checked,
            rejectPersonal: personal.checked,
            requireBreach: breach.checked
        };
    }
    function custom() {
        preset.currentIndex = 3;
        bridge.invalidatePolicy();
    }
    function applyPreset() {
        var p = bridge.policyPreset(preset.currentText);
        minLength.value = p.minLength || 0;
        minScore.value = p.minScore || 0;
        minEntropy.value = p.minEntropy || 0;
        upper.checked = !!p.uppercase;
        lower.checked = !!p.lowercase;
        digits.checked = !!p.digits;
        symbols.checked = !!p.symbols;
        patterns.checked = !!p.rejectPatterns;
        personal.checked = !!p.rejectPersonal;
        breach.checked = !!p.requireBreach;
        bridge.invalidatePolicy();
    }
    AppCard {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            SectionHeader {
                text: "Define what passes"
                Layout.fillWidth: true
            }
            StatusBadge {
                text: "LOCAL POLICY ENGINE"
            }
        }
        AppText {
            Layout.fillWidth: true
            text: "Evaluates the current Analyzer password and its latest manual breach result. NIST-inspired is a starting point, not a claim of official compliance."
            color: Theme.muted
        }
        AppComboBox {
            id: preset
            objectName: "policyPreset"
            Layout.fillWidth: true
            model: ["BALANCED", "HIGH SECURITY", "NIST-INSPIRED", "CUSTOM"]
            onActivated: page.applyPreset()
        }
        GridLayout {
            columns: 6
            columnSpacing: 16
            AppText {
                text: "Min length"
            }
            SpinBox {
                id: minLength
                from: 0
                to: 8192
                value: 16
                editable: true
                onValueModified: page.custom()
            }
            AppText {
                text: "Min score"
            }
            SpinBox {
                id: minScore
                from: 0
                to: 100
                value: 60
                editable: true
                onValueModified: page.custom()
            }
            AppText {
                text: "Min bits"
            }
            SpinBox {
                id: minEntropy
                from: 0
                to: 1000
                value: 0
                editable: true
                onValueModified: page.custom()
            }
        }
        GridLayout {
            columns: 2
            columnSpacing: 30
            Layout.fillWidth: true
            AppCheckBox {
                id: upper
                text: "Require uppercase"
                onClicked: page.custom()
            }
            AppCheckBox {
                id: lower
                text: "Require lowercase"
                onClicked: page.custom()
            }
            AppCheckBox {
                id: digits
                text: "Require a number"
                onClicked: page.custom()
            }
            AppCheckBox {
                id: symbols
                text: "Require a symbol"
                onClicked: page.custom()
            }
            AppCheckBox {
                id: patterns
                text: "Reject common patterns"
                onClicked: page.custom()
            }
            AppCheckBox {
                id: personal
                text: "Reject personal terms"
                onClicked: page.custom()
            }
            AppCheckBox {
                id: breach
                text: "Require manual breach check: no match"
                onClicked: page.custom()
            }
        }
        AppButton {
            objectName: "evaluatePolicyButton"
            text: "Evaluate current Analyzer password"
            primary: true
            enabled: bridge.analysis.length > 0
            onClicked: bridge.evaluatePolicy(page.config())
        }
    }
    AppCard {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            SectionHeader {
                text: "Policy result"
                Layout.fillWidth: true
            }
            StatusBadge {
                text: !bridge.policy.rules ? "NOT EVALUATED" : bridge.policy.passed ? "PASS" : "FAIL"
                tone: !bridge.policy.rules ? Theme.muted : bridge.policy.passed ? Theme.success : Theme.danger
            }
        }
        AppText {
            visible: !bridge.policy.rules
            text: "Run a policy evaluation after analyzing a password."
            color: Theme.muted
            Layout.fillWidth: true
        }
        Repeater {
            model: bridge.policy.rules || []
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                AppText {
                    text: modelData.label
                    Layout.fillWidth: true
                }
                StatusBadge {
                    text: modelData.passed ? "PASS" : "FAIL"
                    tone: modelData.passed ? Theme.success : Theme.danger
                }
            }
        }
        AppText {
            text: "A required breach check fails until a manual lookup completes with no match. Changing the input, breach result or rules invalidates this evaluation."
            color: Theme.muted
            Layout.fillWidth: true
            font.pixelSize: 12
        }
    }
}
