import QtQuick
import QtQuick.Layouts
import "../theme"

AppCard {
    property var finding: ({})
    padding: 12
    spacing: 5
    color: Theme.raised
    AppText {
        Layout.fillWidth: true
        text: (finding.title || "").toUpperCase()
        color: Theme.severity(finding.severity)
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }
    AppText {
        Layout.fillWidth: true
        text: finding.detail || ""
        color: Theme.muted
        font.pixelSize: 12
    }
}
