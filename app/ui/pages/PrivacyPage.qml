import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components"

WorkbenchPage {
    id: page
    function apply() {
        bridge.setPrivacy(offline.checked, mask.checked, clipboard.value, inactivity.value, stats.checked);
    }
    AppCard {
        Layout.fillWidth: true
        SectionHeader {
            text: "Your passwords stay yours"
        }
        AppText {
            Layout.fillWidth: true
            text: "Local analysis. Memory-only inputs. No account, no history, and no telemetry."
            color: Theme.muted
        }
        Repeater {
            model: [
                {
                    label: "LOCAL ANALYSIS",
                    value: "ACTIVE"
                },
                {
                    label: "TELEMETRY",
                    value: "OFF"
                },
                {
                    label: "PASSWORD HISTORY",
                    value: "OFF"
                },
                {
                    label: "AUTO BREACH LOOKUP",
                    value: "OFF"
                }
            ]
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                AppText {
                    text: modelData.label
                    Layout.fillWidth: true
                    font.pixelSize: 12
                }
                StatusBadge {
                    text: modelData.value
                    tone: Theme.success
                }
            }
        }
    }
    AppCard {
        Layout.fillWidth: true
        SectionHeader {
            text: "Session privacy controls"
        }
        AppCheckBox {
            id: mask
            text: "Mask passwords by default"
            checked: true
            onClicked: page.apply()
        }
        AppCheckBox {
            id: offline
            objectName: "offlineOnly"
            text: "Offline-only mode — disable breach requests"
            onClicked: page.apply()
        }
        GridLayout {
            columns: 2
            columnSpacing: 30
            rowSpacing: 12
            AppText {
                text: "Clipboard auto-clear (seconds, 0 = off)"
            }
            SpinBox {
                id: clipboard
                from: 0
                to: 300
                value: 30
                editable: true
                onValueModified: page.apply()
            }
            AppText {
                text: "Inactivity clear (seconds, 0 = off)"
            }
            SpinBox {
                id: inactivity
                from: 0
                to: 3600
                value: 0
                editable: true
                onValueModified: page.apply()
            }
        }
        AppText {
            Layout.fillWidth: true
            text: "Inactivity clearing also clears comparison and generator data. Settings apply to this session only. An already-sent breach request cannot be recalled; its result is discarded after clearing or enabling offline mode."
            color: Theme.muted
            font.pixelSize: 12
        }
    }
    AppCard {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            SectionHeader {
                text: "Session statistics"
                Layout.fillWidth: true
            }
            AppCheckBox {
                id: stats
                text: "Enable"
                onClicked: page.apply()
            }
        }
        AppText {
            Layout.fillWidth: true
            text: "Optional aggregate counts, without password values. Debounced Analyzer runs and comparison analyses each count once. Clear, disable or close to reset."
            color: Theme.muted
            font.pixelSize: 12
        }
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: [
                    {
                        label: "ANALYZED",
                        value: bridge.statistics.analyzed
                    },
                    {
                        label: "AVERAGE SCORE",
                        value: bridge.statistics.average
                    },
                    {
                        label: "WEAK",
                        value: bridge.statistics.weak
                    },
                    {
                        label: "STRONG",
                        value: bridge.statistics.strong
                    },
                    {
                        label: "BREACH MATCHES",
                        value: bridge.statistics.breaches
                    }
                ]
                MetricCard {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    value: modelData.value
                }
            }
        }
    }
    AppCard {
        Layout.fillWidth: true
        border.color: "#442A34"
        SectionHeader {
            text: "Emergency clear"
        }
        AppText {
            Layout.fillWidth: true
            text: "Clear inputs, personal context, analysis, breach results, comparisons, generated values, reveal states, session counts and matching clipboard content."
            color: Theme.muted
        }
        AppButton {
            objectName: "privacyClearButton"
            text: "Clear sensitive data  ·  Ctrl + Shift + X"
            destructive: true
            onClicked: bridge.clearSensitiveData()
        }
        AppText {
            Layout.fillWidth: true
            text: "Clearing releases application-held values. Python and Qt cannot guarantee forensic erasure of immutable strings, operating-system swap, clipboard history or third-party clipboard tools."
            color: Theme.muted
            font.pixelSize: 12
        }
    }
}
