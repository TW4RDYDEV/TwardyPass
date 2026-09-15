import QtQuick
import QtQuick.Controls
import "../theme"

TextField {
    id: control
    implicitHeight: 42
    color: Theme.text
    placeholderTextColor: Theme.muted
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    leftPadding: 12
    rightPadding: 12
    font.pixelSize: 13
    selectByMouse: true
    background: Rectangle {
        color: Theme.background
        radius: 7
        border.color: control.activeFocus ? Theme.accent : Theme.border
    }
}
