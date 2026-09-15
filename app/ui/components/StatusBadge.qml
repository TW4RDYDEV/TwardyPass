import QtQuick
import "../theme"

Rectangle {
    id: badge
    property string text: "LOCAL"
    property color tone: Theme.accent
    implicitWidth: label.implicitWidth + 20
    implicitHeight: 28
    radius: 6
    color: Qt.rgba(tone.r, tone.g, tone.b, 0.09)
    border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.28)
    Text {
        id: label
        anchors.centerIn: parent
        text: badge.text
        textFormat: Text.PlainText
        color: badge.tone
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 0.5
    }
}
