import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: control
    property bool primary: false
    property bool destructive: false
    implicitHeight: 40
    leftPadding: 15
    rightPadding: 15
    font.pixelSize: 12
    font.weight: Font.DemiBold
    opacity: enabled ? 1 : 0.4
    contentItem: Text {
        text: control.text
        font: control.font
        textFormat: Text.PlainText
        color: control.primary ? Theme.background : control.destructive ? Theme.danger : Theme.text
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
    background: Rectangle {
        radius: 7
        color: control.primary ? Theme.accent : control.hovered ? "#192331" : Theme.raised
        border.color: control.activeFocus ? Theme.accent : Theme.border
        border.width: 1
    }
}
