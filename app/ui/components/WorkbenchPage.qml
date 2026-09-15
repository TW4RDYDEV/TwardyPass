import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    default property alias body: bodyColumn.data
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ColumnLayout {
        id: bodyColumn
        x: 28
        y: 12
        width: Math.max(0, page.availableWidth - 56)
        spacing: 18
    }
    contentHeight: bodyColumn.implicitHeight + 40
}
