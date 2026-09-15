import QtQuick
import QtQuick.Layouts
import "../theme"

AppCard {
    property string label: ""
    property string value: "—"
    padding: 16
    spacing: 8
    AppText {
        text: label
        color: Theme.muted
        font.pixelSize: 10
        font.letterSpacing: 0.6
        Layout.fillWidth: true
    }
    AppText {
        text: value
        font.pixelSize: 21
        font.weight: Font.DemiBold
        Layout.fillWidth: true
    }
}
