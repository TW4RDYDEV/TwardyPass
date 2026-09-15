import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"
import "components"
import "pages"

ApplicationWindow {
    id: window
    objectName: "mainWindow"
    width: 1440
    height: 900
    minimumWidth: 1180
    minimumHeight: 720
    visible: true
    title: "TwardyPass " + bridge.version + " — Password Security Workbench"
    color: Theme.background
    font.family: "Segoe UI"
    font.pixelSize: 13
    palette.window: Theme.background
    palette.windowText: Theme.text
    palette.base: Theme.surface
    palette.text: Theme.text
    palette.button: Theme.raised
    palette.buttonText: Theme.text
    palette.highlight: Theme.accent
    palette.highlightedText: Theme.background
    palette.mid: Theme.border
    palette.light: Theme.border
    palette.dark: Theme.background
    property int currentPage: 0
    property var pageNames: ["Analyzer", "Generator", "Compare Lab", "Policy Lab", "Privacy Center", "About"]
    Shortcut {
        sequence: "Ctrl+Shift+X"
        context: Qt.ApplicationShortcut
        autoRepeat: false
        onActivated: bridge.clearSensitiveData()
    }
    onClosing: bridge.clearSensitiveData()
    Rectangle {
        id: sidebar
        width: 216
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Theme.sidebar
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Theme.border
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 7
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 9
                Layout.bottomMargin: 26
                spacing: 9
                Image {
                    source: "../../assets/TwardyPass-app-icon.png"
                    sourceSize.width: 48
                    sourceSize.height: 48
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                }
                Column {
                    spacing: 3
                    AppText {
                        text: "TwardyPass"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    AppText {
                        text: "by TWARDY.exe"
                        color: Theme.muted
                        font.pixelSize: 10
                    }
                }
            }
            AppText {
                text: "WORKSPACE"
                color: Theme.muted
                font.pixelSize: 9
                font.letterSpacing: 1.6
                Layout.leftMargin: 16
                Layout.bottomMargin: 7
            }
            Repeater {
                model: window.pageNames
                NavigationItem {
                    required property int index
                    required property string modelData
                    objectName: "nav" + index
                    Layout.fillWidth: true
                    text: modelData
                    number: "0" + (index + 1)
                    selected: window.currentPage === index
                    onClicked: {
                        window.currentPage = index;
                        bridge.touchActivity();
                    }
                }
            }
            Item {
                Layout.fillHeight: true
            }
            StatusBadge {
                text: bridge.offlineOnly ? "OFFLINE ONLY" : "LOCAL ANALYSIS"
                tone: Theme.success
                Layout.leftMargin: 8
            }
            AppText {
                text: "No history. No telemetry.\nYour workspace stays local."
                font.pixelSize: 11
                color: Theme.muted
                Layout.fillWidth: true
                Layout.margins: 8
            }
            AppButton {
                text: "Clear sensitive data"
                objectName: "panicButton"
                Layout.fillWidth: true
                destructive: true
                onClicked: bridge.clearSensitiveData()
            }
            AppText {
                text: "Ctrl + Shift + X     /     v" + bridge.version
                color: Theme.muted
                font.pixelSize: 10
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 5
            }
        }
    }
    ColumnLayout {
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 94
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Column {
                spacing: 6
                AppText {
                    text: "PASSWORD SECURITY WORKBENCH"
                    color: Theme.muted
                    font.pixelSize: 9
                    font.letterSpacing: 1.8
                }
                AppText {
                    text: window.pageNames[window.currentPage]
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }
            }
            Item {
                Layout.fillWidth: true
            }
            StatusBadge {
                text: "PRIVATE BY DESIGN"
                tone: Theme.muted
            }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.currentPage
            AnalyzerPage {
                objectName: "analyzerPage"
            }
            GeneratorPage {
                objectName: "generatorPage"
            }
            ComparePage {
                objectName: "comparePage"
            }
            PolicyPage {
                objectName: "policyPage"
            }
            PrivacyPage {
                objectName: "privacyPage"
            }
            AboutPage {
                objectName: "aboutPage"
            }
        }
    }
    Toast {
        id: toast
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
    }
    Connections {
        target: bridge
        function onToastRequested(title, message) {
            toast.show(title, message);
        }
    }
}
