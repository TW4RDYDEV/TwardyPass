import QtQuick
import QtQuick.Layouts
import "../theme"

AppCard {
    id: toast
    property string heading: ""
    property string message: ""
    width: 390
    visible: timer.running
    z: 100
    border.color: "#34485E"
    function show(title, detail) {
        heading = title;
        message = detail;
        timer.restart();
    }
    AppText {
        Layout.fillWidth: true
        text: toast.heading
        font.weight: Font.DemiBold
    }
    AppText {
        Layout.fillWidth: true
        text: toast.message
        color: Theme.muted
        font.pixelSize: 12
    }
    Timer {
        id: timer
        interval: 3400
    }
}
