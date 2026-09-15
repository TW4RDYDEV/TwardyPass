import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: nav
    property bool selected: false
    property string number: "01"
    implicitHeight: 44
    leftPadding: 16
    contentItem: Text {
        text: nav.number + "    " + nav.text
        color: nav.selected ? Theme.text : Theme.muted
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 7
        color: nav.selected ? Theme.raised : nav.hovered ? Theme.surface : "transparent"
        border.color: nav.activeFocus ? Theme.accent : "transparent"
        Rectangle {
            width: 3
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent
            visible: nav.selected
        }
    }
}
