import QtQuick
import QtQuick.Controls
import "../theme"

ComboBox {
    id: control
    implicitHeight: 42
    leftPadding: 12
    rightPadding: 34
    font.pixelSize: 12
    contentItem: Text {
        text: control.displayText
        font: control.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Text {
        text: "⌄"
        color: Theme.muted
        font.pixelSize: 22
        x: control.width - width - 13
        anchors.verticalCenter: parent.verticalCenter
    }
    background: Rectangle {
        color: Theme.raised
        radius: 7
        border.color: control.activeFocus ? Theme.accent : Theme.border
    }
}
