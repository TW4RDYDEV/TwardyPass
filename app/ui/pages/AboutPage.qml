import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

WorkbenchPage {
    AppCard {
        Layout.fillWidth: true
        padding: 28
        RowLayout {
            spacing: 24
            Layout.fillWidth: true
            Image {
                source: "../../../assets/TwardyPass-app-icon.png"
                sourceSize.width: 128
                sourceSize.height: 128
                Layout.preferredWidth: 112
                Layout.preferredHeight: 112
            }
            ColumnLayout {
                Layout.fillWidth: true
                AppText {
                    text: "TwardyPass"
                    font.pixelSize: 34
                    font.weight: Font.DemiBold
                }
                AppText {
                    text: "Password Security Workbench"
                    color: Theme.muted
                    font.pixelSize: 17
                }
                AppText {
                    text: "by TWARDY.exe  /  TW4RDYDEV"
                    color: Theme.accent
                }
                AppText {
                    text: "Copyright (c) 2026 Filip Twardowski. All rights reserved."
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
                StatusBadge {
                    text: "VERSION " + bridge.version
                }
            }
        }
        AppText {
            Layout.fillWidth: true
            text: "Version 1.1.0 introduces a redesigned interface, expanded analysis, Policy Lab, reports, and Windows packaging."
            color: Theme.muted
        }
    }
    AppCard {
        Layout.fillWidth: true
        SectionHeader {
            text: "License"
        }
        AppText {
            text: bridge.licenseInfo.name
            font.pixelSize: 18
            Layout.fillWidth: true
        }
        AppText {
            text: bridge.licenseInfo.summary
            color: Theme.muted
            Layout.fillWidth: true
        }
        AppText {
            text: bridge.licenseInfo.commercial
            visible: text.length > 0
            color: Theme.warning
            Layout.fillWidth: true
        }
        AppText {
            text: "This status is derived locally from the bundled LICENSE. The complete LICENSE is the legal source of truth."
            color: Theme.muted
            Layout.fillWidth: true
            font.pixelSize: 12
        }
    }
    AppCard {
        Layout.fillWidth: true
        SectionHeader {
            text: "Project & acknowledgements"
        }
        AppText {
            text: "Repository: github.com/TW4RDYDEV/TwardyPass"
            Layout.fillWidth: true
        }
        AppText {
            text: "Python · PySide6 / Qt Quick · zxcvbn · requests · ReportLab · PyInstaller"
            color: Theme.muted
            Layout.fillWidth: true
        }
        AppText {
            text: "Password estimation by zxcvbn. Optional breach intelligence from Have I Been Pwned, Pwned Passwords. All third-party components retain their respective licenses."
            color: Theme.muted
            Layout.fillWidth: true
        }
        AppText {
            text: "Analysis is local; breach lookups are manual. No telemetry, password history, online activation or accounts."
            color: Theme.muted
            Layout.fillWidth: true
        }
        AppButton {
            text: "Open project repository"
            onClicked: Qt.openUrlExternally("https://github.com/TW4RDYDEV/TwardyPass")
        }
    }
}
