import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: card
    default property alias content: body.data
    property int padding: 22
    property int spacing: 14
    color: Theme.surface
    radius: 12
    border.color: Theme.border
    clip: true
    implicitHeight: body.implicitHeight + padding * 2
    ColumnLayout {
        id: body
        x: card.padding
        y: card.padding
        width: Math.max(0, card.width - card.padding * 2)
        spacing: card.spacing
    }
}
